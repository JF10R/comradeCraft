-- Options: native Blizzard Options panel (Esc -> Options -> AddOns -> ComradeCraft).
-- Leatrix-style per-module toggles, UI scale, minimap visibility, sound toggle, and position reset.
local _, ns = ...
local L = ns.L

local Options = {}
ns.Options = Options

local categoryID
local panel

local PANEL_LIST = {
  { "mail",     L["Mailbox panel"] },
  { "bank",     L["Bank panel"] },
  { "trade",    L["Trade panel"] },
  { "merchant", L["Merchant panel"] },
  { "trainer",  L["Trainer panel"] },
  { "ah",       L["Auction House panel"] },
}

local function BuildPanel()
  if panel then return panel end
  panel = CreateFrame("Frame", "ComradeCraftOptionsPanel")
  panel.name = "ComradeCraft"

  local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("ComradeCraft")

  local sub = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
  sub:SetText(L["Configure companion panels, UI scale, sounds, and window positions."])

  local openBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  openBtn:SetSize(160, 24)
  openBtn:SetPoint("TOPLEFT", 16, -58)
  openBtn:SetText(L["Open ComradeCraft"])
  openBtn:SetScript("OnClick", function()
    if ns.ToggleWindow then
      if not (ComradeCraftFrame and ComradeCraftFrame:IsShown()) then ns.ToggleWindow() end
    end
  end)

  local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  resetBtn:SetSize(210, 24)
  resetBtn:SetPoint("LEFT", openBtn, "RIGHT", 10, 0)
  resetBtn:SetText(L["Reset window positions"])
  resetBtn:SetScript("OnClick", function()
    if ns.ResetPositions then ns.ResetPositions() end
  end)

  -- UI Scale control (75% to 125% in 5% steps).
  local scaleHead = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  scaleHead:SetPoint("TOPLEFT", 16, -98)
  scaleHead:SetText(L["Window scale"])

  local scaleVal = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  local function UpdateScaleText()
    local s = ns.UIScale and ns.UIScale() or 1
    scaleVal:SetText(("%d%%"):format(math.floor(s * 100 + 0.5)))
  end

  local minusBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  minusBtn:SetSize(28, 22)
  minusBtn:SetPoint("TOPLEFT", 16, -118)
  minusBtn:SetText("-")
  minusBtn:SetScript("OnClick", function()
    if ns.SetUIScale then ns.SetUIScale((ns.UIScale() or 1) - 0.05) end
    UpdateScaleText()
  end)

  scaleVal:SetPoint("LEFT", minusBtn, "RIGHT", 10, 0)
  scaleVal:SetWidth(46)
  scaleVal:SetJustifyH("CENTER")

  local plusBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  plusBtn:SetSize(28, 22)
  plusBtn:SetPoint("LEFT", scaleVal, "RIGHT", 10, 0)
  plusBtn:SetText("+")
  plusBtn:SetScript("OnClick", function()
    if ns.SetUIScale then ns.SetUIScale((ns.UIScale() or 1) + 0.05) end
    UpdateScaleText()
  end)

  local defScaleBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  defScaleBtn:SetSize(74, 22)
  defScaleBtn:SetPoint("LEFT", plusBtn, "RIGHT", 10, 0)
  defScaleBtn:SetText("100%")
  defScaleBtn:SetScript("OnClick", function()
    if ns.SetUIScale then ns.SetUIScale(1.0) end
    UpdateScaleText()
  end)

  -- Companion panels (2-column grid of checkboxes).
  local compHead = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  compHead:SetPoint("TOPLEFT", 16, -156)
  compHead:SetText(L["Companion panels"])

  local checks = {}
  local function MakeCheck(x, y, label, getter, setter)
    local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb:SetPoint("TOPLEFT", x, y)
    cb.label = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cb.label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    cb.label:SetText(label)
    cb:SetScript("OnClick", function(self) setter(self:GetChecked() == true) end)
    checks[#checks + 1] = { cb = cb, get = getter }
    return cb
  end

  for i, p in ipairs(PANEL_LIST) do
    local key, lbl = p[1], p[2]
    local col = (i - 1) % 2
    local row = math.floor((i - 1) / 2)
    MakeCheck(16 + col * 220, -176 - row * 28, lbl,
      function() return ns.PanelEnabled(key) end,
      function(on) ns.SetPanelEnabled(key, on) end)
  end

  -- General & Interface toggles.
  local genHead = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  genHead:SetPoint("TOPLEFT", 16, -274)
  genHead:SetText(L["Interface"])

  MakeCheck(16, -294, L["Show minimap button"],
    function() return not (ComradeCraftDB and ComradeCraftDB.minimap and ComradeCraftDB.minimap.hide) end,
    function(on) if ns.SetMinimapShown then ns.SetMinimapShown(on) end end)

  MakeCheck(236, -294, L["Play sound notifications"],
    function() return not (ComradeCraftDB and ComradeCraftDB.settings and ComradeCraftDB.settings.sounds == false) end,
    function(on)
      ComradeCraftDB.settings = ComradeCraftDB.settings or {}
      ComradeCraftDB.settings.sounds = on
    end)

  MakeCheck(16, -322, L["Highlight items for your group in your bags (and focus a recipient's items when mailing)."],
    function() return ns.Bags and ns.Bags.On() or false end,
    function(on) if ns.Bags then ns.Bags.Set(on) end end)

  MakeCheck(16, -350, L["Show the step panel next to the profession window."],
    function() return ns.TrackerOn and ns.TrackerOn() or false end,
    function(on) if ns.SetTracker then ns.SetTracker(on) end end)

  MakeCheck(16, -378, L["Show the wishlist tracker on screen (pinned crafts)."],
    function() return ns.Wishlist and ns.Wishlist.TrackerOn() or false end,
    function(on) if ns.Wishlist then ns.Wishlist.SetTracker(on) end end)

  MakeCheck(16, -406, L["Show the farming tracker (your farming assignments from the Group plan)."],
    function() return ns.FarmTrackerOn and ns.FarmTrackerOn() or false end,
    function(on) if ns.SetFarmTracker then ns.SetFarmTracker(on) end end)

  panel:SetScript("OnShow", function()
    UpdateScaleText()
    for _, c in ipairs(checks) do c.cb:SetChecked(c.get() and true or false) end
  end)
  UpdateScaleText()
  return panel
end

function Options.Register()
  local p = BuildPanel()
  if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
    local ok, cat = pcall(Settings.RegisterCanvasLayoutCategory, p, "ComradeCraft", "ComradeCraft")
    if ok and cat then
      pcall(Settings.RegisterAddOnCategory, cat)
      categoryID = cat.GetID and cat:GetID() or cat.ID
    end
  elseif InterfaceOptions_AddCategory then
    pcall(InterfaceOptions_AddCategory, p)
  end
end

function ns.OpenOptions()
  if categoryID and Settings and Settings.OpenToCategory then
    Settings.OpenToCategory(categoryID)
  elseif panel and InterfaceOptionsFrame_OpenToCategory then
    InterfaceOptionsFrame_OpenToCategory(panel)
    InterfaceOptionsFrame_OpenToCategory(panel)
  elseif ns.ToggleWindow then
    ComradeCraftDB.ui = ComradeCraftDB.ui or {}
    ComradeCraftDB.ui.sel = "manage"
    if not (ComradeCraftFrame and ComradeCraftFrame:IsShown()) then ns.ToggleWindow() else ns.RefreshWindow() end
  end
end

ns.On("PLAYER_LOGIN", function()
  Options.Register()
end)

ns.commands.options = ns.OpenOptions
