# Publishing on CurseForge (not done yet)

State: name "ComradeCraft" looked free on 2026-11-11 (curseforge.com/wow/addons/comradecraft
returned 404; no search hit on CurseForge, Wago or WoWInterface). Packaging files are ready
(`.pkgmeta`, `.github/workflows/release.yml`, `LICENSE`, `CHANGELOG.md`). No GitHub repo yet.

Steps when ready:

1. Create the CurseForge project (World of Warcraft, name ComradeCraft, license MIT).
   Copy its Project ID into `ComradeCraft/ComradeCraft.toc` as `## X-Curse-Project-ID: <id>`.
2. Create a CurseForge API token (CurseForge account > API tokens).
3. Create the GitHub repository, push, and add the secret `CF_API_TOKEN`.
4. Tag a version and push it: `git tag v0.1.0 && git push origin v0.1.0`.
   The workflow builds `ComradeCraft-v0.1.0.zip` and uploads it.

Open points:

- The packager detects the game version from `## Interface: 16001`; its README lists 16001
  ("Forever Beta") but the CurseForge version mapping was not tested. If the upload is
  rejected, pass the version explicitly in the workflow (`args: -g 1.60.1`).
- LibDataBroker and LibDBIcon have no license file (see THIRD_PARTY.md).
- `## Version: @project-version@` is replaced in the zip only; a local copy shows the literal.
