-- Pricing: AH price sources (live scans, TSM, Auctionator), vendor item list,
-- deposit estimates, BoP checks, and resale options (vendor / disenchant / AH).
local _, ns = ...

-- Reagents sold by vendors (checked against ItemSparse names, build 1.60.1.70888), plus
-- whatever the addon has seen on merchants (ComradeCraftDB.vendorSeen). Not group needs.
ns.VENDOR_ITEMS = {
  [2320] = true, [2321] = true, [4291] = true, [8343] = true, [14341] = true, -- threads
  [4340] = true, [6260] = true, [2604] = true, [4341] = true, [2605] = true, -- dyes
  [2325] = true, [6261] = true, [4342] = true, [10290] = true, [2324] = true, -- dyes, bleach
  [2678] = true, [2692] = true, [3713] = true, [159] = true, [1179] = true,   -- cooking
  [3371] = true, [3372] = true, [8925] = true, [18256] = true,                -- vials
  [2880] = true, [3466] = true, [3857] = true, [4289] = true, [4470] = true,  -- flux, coal, salt, wood
  [6217] = true, [814] = true, [4399] = true, [4400] = true,                  -- rod, oil, stocks
  [2928] = true, [2930] = true, [8923] = true, [8924] = true, [5173] = true,  -- poison reagents
  [249409] = true, [249430] = true, [249431] = true, [18567] = true, [11291] = true, -- dyes, flux, wood (1.60.1.71139)
}

function ns.IsVendorItem(id)
  return ns.VENDOR_ITEMS[id] or (ComradeCraftDB and ComradeCraftDB.vendorSeen
    and ComradeCraftDB.vendorSeen[id]) or false
end

local AH_PRICE_TTL = 86400 -- 24 h freshness window for directly scanned AH prices
local AH_REF_TTL = 7 * 86400 -- scanned prices kept this long as deal benchmarks (ns.ReferencePrice)

function ns.LiveAHPrice(item)
  local e = ComradeCraftDB and ComradeCraftDB.ahPrices and ComradeCraftDB.ahPrices[item]
  if e and e.price and e.price > 0 and (time() - (e.t or 0)) <= AH_PRICE_TTL then return e.price end
end

local function HasTSM() return TSM_API ~= nil and TSM_API.GetCustomPriceValue ~= nil end
local function HasAuc()
  return Auctionator ~= nil and Auctionator.API ~= nil and Auctionator.API.v1 ~= nil
    and Auctionator.API.v1.GetAuctionPriceByItemID ~= nil
end
local function TSMPrice(item)
  if not HasTSM() then return nil end
  local key = "i:" .. item
  for _, expr in ipairs({ "DBMinBuyout", "DBRecent", "DBMarket" }) do
    local ok, v = pcall(TSM_API.GetCustomPriceValue, expr, key)
    if ok and type(v) == "number" and v > 0 then return v end
  end
end
local function AucPrice(item)
  if not HasAuc() then return nil end
  local ok, v = pcall(Auctionator.API.v1.GetAuctionPriceByItemID, "ComradeCraft", item)
  if ok and type(v) == "number" and v > 0 then return v end
end

-- True only when TSM or Auctionator prices items (live scans cover just what you browsed).
function ns.PriceSourceIsComplete()
  return HasTSM() or HasAuc()
end

-- Deal benchmark that ignores the scan in progress: TSM, Auctionator, else the scanned price
-- stored before this scan (Scan.lua keeps it as `prev`).
function ns.ReferencePrice(item)
  local v = TSMPrice(item) or AucPrice(item)
  if v then return v end
  local e = ComradeCraftDB and ComradeCraftDB.ahPrices and ComradeCraftDB.ahPrices[item]
  if e and (e.prev or 0) > 0 and (time() - (e.prevT or 0)) <= AH_REF_TTL then return e.prev end
end

-- Auction prices from live AH scans, TSM (latest buyout/recent/market) and/or Auctionator.
-- When both TSM and Auctionator are loaded, falls back cleanly between them so new/rare items
-- still get a price. Sets ns.PriceSource(itemID) -> copper|nil and ns.PriceSourceName.
function ns.DetectPriceSource()
  local hasTSM, hasAuc = HasTSM(), HasAuc()
  -- Drop scans past the benchmark window; only fresh ones make "AH" a price source.
  local hasLive, prices, now = false, ComradeCraftDB and ComradeCraftDB.ahPrices, time()
  for id, e in pairs(prices or {}) do
    local age = now - (type(e) == "table" and e.t or 0)
    if age > AH_REF_TTL then prices[id] = nil elseif age <= AH_PRICE_TTL then hasLive = true end
  end
  if hasTSM or hasAuc or hasLive then
    ns.PriceSourceName = hasTSM and hasAuc and "TSM + Auctionator"
      or hasTSM and "TSM" or hasAuc and "Auctionator" or "AH"
    ns.PriceSource = function(item)
      return ns.LiveAHPrice(item) or TSMPrice(item) or AucPrice(item)
    end
  else
    ns.PriceSource, ns.PriceSourceName = nil, nil
  end
  -- Disenchant value of an item (AH value of its expected mats): TSM "Destroy", else Auctionator.
  ns.DisenchantPrice = nil
  local hasAucDE = Auctionator and Auctionator.API and Auctionator.API.v1
    and Auctionator.API.v1.GetDisenchantPriceByItemID ~= nil
  if hasTSM or hasAucDE then
    ns.DisenchantPrice = function(item)
      if hasTSM then
        local ok, v = pcall(TSM_API.GetCustomPriceValue, "Destroy", "i:" .. item)
        if ok and type(v) == "number" and v > 0 then return v end
      end
      if hasAucDE then
        local ok, v = pcall(Auctionator.API.v1.GetDisenchantPriceByItemID, "ComradeCraft", item)
        if ok and type(v) == "number" and v > 0 then return v end
      end
    end
  end
end
ns.On("PLAYER_LOGIN", function()
  ns.DetectPriceSource()
  ns.RequestRefresh()
end)
ns.On("AUCTION_HOUSE_CLOSED", function()
  ns.DetectPriceSource()
  ns.RequestRefresh()
end)

-- Cost of buying `n` of an item, in copper, or nil when no real price is known:
-- AH price, or the merchant buy price for vendor reagents. Never the sell-price proxy.
function ns.BuyCost(item, n)
  if ns.IsVendorItem(item) then
    local p = ns.ItemPrices and ns.ItemPrices[item]
    if p and p[2] > 0 then return p[2] * n end
  end
  local v = ns.PriceSource and ns.PriceSource(item)
  return v and v > 0 and v * n or nil
end

-- Value of one item in copper: AH price if a source is plugged in (ns.PriceSource),
-- else the merchant price (buy price for vendor reagents, sell price otherwise). Min 1.
function ns.ItemValue(item)
  local v = ns.PriceSource and ns.PriceSource(item)
  if v and v > 0 then return v end
  local p = ns.ItemPrices and ns.ItemPrices[item]
  if p then
    v = (ns.IsVendorItem(item) and p[2] > 0) and p[2] or p[1]
  end
  return math.max(1, v or 1)
end

-- AH deposit, per item: measured when you post (Shopping.lua), else merchant price x ratio.
-- DEPOSIT_LOSS: share counted as lost. Forever refunds it on sale (sale mail: 2s99 + 1s deposit
-- - 14c cut = 3s85), so only expired auctions lose it; we assume a quarter expire once.
ns.DEPOSIT_LOSS = 0.25
-- Forever, 2 h auctions: 5% of the merchant sell price, at least 1c (about 40 deposits measured
-- in game, e.g. Greater Magic Wand sell 2s -> 10c). Longer durations cost more; not modeled.
ns.DEPOSIT_MIN, ns.DEPOSIT_RATIO = 1, 0.05
ns.AH_MARGIN = 1.1 -- the AH must beat the merchant/disenchant by 10% (time, competition)

-- How many of an item the AH absorbs over a leveling session: sales per day x SALE_DAYS, from
-- ComradeCraftDB.saleRates (an open slot any addon may fill: [itemID] = { perDay, t }, used
-- while under a week old), else TSM, else DEFAULT_SALE_CAP. The rest counts at the merchant
-- or disenchant value.
ns.SALE_DAYS = 3
ns.DEFAULT_SALE_CAP = 5
ns.SALE_RATE_TTL = 7 * 86400
function ns.SaleCap(item)
  local r = ComradeCraftDB and ComradeCraftDB.saleRates and ComradeCraftDB.saleRates[item]
  if type(r) == "table" and type(r.perDay) == "number" and r.perDay >= 0
    and (time() - (r.t or 0)) <= ns.SALE_RATE_TTL then
    return math.floor(r.perDay * ns.SALE_DAYS)
  end
  if TSM_API and TSM_API.GetCustomPriceValue then
    local ok, v = pcall(TSM_API.GetCustomPriceValue, "DBRegionSoldPerDay*1000", "i:" .. item)
    if ok and type(v) == "number" then return math.floor(v / 1000 * ns.SALE_DAYS) end
  end
  return ns.DEFAULT_SALE_CAP
end

function ns.AuctionDeposit(item)
  local db = ComradeCraftDB
  local d = db and db.deposits and db.deposits[item]
  if d and d > 0 then return d end
  local p = ns.ItemPrices and ns.ItemPrices[item]
  local sell = p and p[1]
  if not sell then
    local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    sell = get and select(11, get(item))
  end
  return math.max(ns.DEPOSIT_MIN, math.floor((sell or 0) * ns.DEPOSIT_RATIO))
end

-- True for Bind on Pickup (1) and Quest (4) items: cannot be auctioned or mailed to others.
function ns.IsBoP(item)
  if not item or item == 0 then return false end
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local bind = get and select(14, get(item))
  return bind == 1 or bind == 4
end

-- What one crafted item brings back, three ways: merchant sell price, disenchant (AH value
-- of its mats; nil if unknown), auction house (price - 5% cut - expected deposit loss; nil
-- without a price source or for BoP items). deposit = the full deposit, for display.
function ns.ResaleOptions(item)
  if not item or item == 0 then return { vendor = 0 } end
  local p = ns.ItemPrices and ns.ItemPrices[item]
  local vendor = p and p[1] or 0
  if vendor == 0 then
    local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    vendor = (get and select(11, get(item))) or 0
  end
  local ah = not ns.IsBoP(item) and ns.PriceSource and ns.PriceSource(item) or nil
  local de = ns.DisenchantPrice and ns.DisenchantPrice(item)
  if not de and ns.DisenchantEstimate then de = ns.DisenchantEstimate(item) end
  local o = { vendor = vendor, de = de }
  if ah and ah > 0 then
    o.deposit = ns.AuctionDeposit(item)
    o.ah = ah * 0.95 - o.deposit * ns.DEPOSIT_LOSS
  end
  return o
end

-- The best way to sell (o = ResaleOptions, values may be scaled): the AH only when it beats
-- the merchant and the disenchant by AH_MARGIN.
function ns.BestResale(o)
  local other = math.max(o.vendor or 0, o.de or 0)
  if o.ah and o.ah > other * ns.AH_MARGIN then return o.ah end
  return other
end

-- What the "profitable" route counts on.
function ns.ResaleValue(item)
  return ns.BestResale(ns.ResaleOptions(item))
end
