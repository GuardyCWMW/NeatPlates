# NeatPlates Contributor and Agent Guide

## Purpose and scope

NeatPlates Community Edition maintains the existing NeatPlates/Tidy Plates
nameplate experience across WoW clients. Prioritize compatibility, stability,
existing profiles, and familiar behavior over redesigns. This guide applies to
the whole repository; `CLAUDE.md` and `.github\copilot-instructions.md` point here.

The current-state sections describe existing code. The roadmap describes
proposals, not implemented capabilities or permission to expand a task.

### Project provenance and references

- CE retains the architecture and much of the source of
  [Luxocracy/NeatPlates](https://github.com/Luxocracy/NeatPlates). Upstream
  `v468` (`250535d347011e9970292a7781633b10bdf28018`) is the recorded comparison
  baseline, not a shared Git ancestor. CE currently has an independent Git
  history; do not assume normal upstream merges have a valid merge base.
- Link players to the
  [CE CurseForge project](https://www.curseforge.com/wow/addons/neatplates-community-edition-mop-classic);
  retain the [original project](https://www.curseforge.com/wow/addons/neatplates)
  in credits. Preserve attribution and license notices in distributions.
- Original NeatPlates and Threat Plates share Tidy Plates ancestry, but their
  implementations have diverged. Threat Plates is an architectural reference,
  not a drop-in dependency. Do not transplant code without checking its license
  and client/runtime assumptions.

## Current architecture

### Runtime and supported clients

- This is a WoW addon suite using Blizzard's customized Lua 5.1-based runtime,
  XML UI definitions, and TOC manifests. It is not a standalone Lua application.
- `README.md` declares support for Forever, Retail, MoP Classic, TBC Anniversary,
  and Classic Era. Historical Wrath/Cata manifests and code also remain; their
  presence alone does not establish current support or testing.
- `NeatPlates\NeatPlatesGlobals.lua` establishes `NEATPLATES_IS_*` flags.
  Forever is deliberately included in `NEATPLATES_IS_RETAIL` for modern UI and
  secret-value handling; do not interpret that flag as Retail-only.
- `NeatPlates\NeatPlatesForever.lua` is loaded early by the Camelot manifest
  to mark Forever and provide specialization API compatibility aliases.

### Addon boundaries

Each top-level addon folder is a separate WoW loading unit, not merely a source
package. Dependencies in its selected TOC control ordering and availability.

| Location             | Existing responsibility                                                                                            |
|----------------------|--------------------------------------------------------------------------------------------------------------------|
| `NeatPlates`         | Nameplate lifecycle, rendering, theme loading, base settings UI, utilities, localization, and embedded libraries   |
| `NeatPlatesWidgets`  | Widget factories and tracking for auras, resources, classes, threat, quests, and other indicators; depends on core |
| `NeatPlatesHub`      | Profiles, configuration UI, and shared theme behavior; depends on core and widgets                                 |
| `NeatPlates_*`       | Theme definitions and artwork; bundled themes generally depend on core and Hub                                     |
| `NeatPlates\libs`    | Vendored third-party code; preserve upstream licenses and keep routine project refactors out                       |
| `NeatPlates\locales` | AceLocale translations; `enUS.lua` is the base locale                                                              |

The normal dependency order is core -> widgets -> Hub -> themes. This is a
practical modular split, not a strict layered architecture: global APIs,
callbacks, and some core-to-Hub references couple the pieces.

### Loading and module communication

- WoW selects an appropriate TOC for the client. Follow that manifest and its
  XML includes to find active code; a Lua file's presence does not mean it runs.
  Both hyphenated and underscored flavor manifests exist. Do not rename or
  consolidate them without checking client selection and release behavior.
- Core manifests load library embeds and localization before `NeatPlates.xml`.
  That XML loads Globals, Statusbar, Utility, Core, Template, Parser, and Panel
  in that order, alongside UI template definitions.
- Hub loads Defaults, Helpers, Templates, then its `functions` files, then
  `Hub.lua`. Earlier files establish tables and functions consumed by later ones.
- Mainline widgets use `Widgets-Mainline.xml` and `AuraWidget-Mainline.lua`;
  other manifests can use `Widgets.xml` and `AuraWidget.lua`. Library embed
  lists also differ across clients.
- `local addonName, Addon = ...` receives a private table shared by files within
  one addon. Core calls it `NeatPlatesInternal`; Hub calls it `HubData`.
  Separate addon folders do not share that private table.
- Cross-addon APIs are globals, because separate addon folders cannot share a
  private table. The known deliberate globals include `NeatPlates`,
  `NeatPlatesUtility`, `NeatPlatesWidgets`, `NeatPlatesHubFunctions`,
  `NeatPlatesThemeList`, `NeatPlatesCore`, `NeatPlatesEventFrame`,
  `NeatPlatesPanel`, `NeatPlatesSpellDB`, `NeatPlatesTarget`,
  `NeatPlatesBackdrop`, `NeatPlatesHubHelpers`, `NeatPlatesHubMenus`,
  `NeatPlatesHubRapidPanel`, `NeatPlatesHubPrefixList`, and
  `NeatPlatesWidgetSettings`. Treat this list as indicative, not exhaustive:
  confirm with a repository-wide search before localizing, renaming, or
  removing any global. Converting one of these to a local is a silent
  cross-addon break that no syntax check will catch.
  Do not introduce standard `require`/LuaRocks dependencies into runtime code.

### Main execution flow

1. `NeatPlatesCore.lua` handles nameplate creation, unit addition/removal,
   health/casting updates, target changes, and combat state. Frame event
   handlers and an `OnUpdate` loop drive rendering and requested updates.
2. `NeatPlatesTemplate.lua` defines a baseline theme.
   `NeatPlatesParser.lua` merges selected theme data with that baseline,
   activates it, and requests refreshes.
3. Themes register tables in `NeatPlatesThemeList`. The usual registration
   contract is `NeatPlatesThemeList[ThemeName] = Theme` followed by
   `NeatPlatesHubFunctions.ApplyHubFunctions(Theme)`, which attaches shared
   behavior. Bundled themes mostly supply style data and artwork and let Hub
   provide the behavior, so a hook listed below is often Hub's, not the theme's.
4. `NeatPlatesHub\functions\Core.lua` coordinates active profile values,
   callbacks, theme activation, and behavior attachment. The neighboring
   Filter, Style, Alpha, Scale, Color, Text, and Widgets files supply policies.
5. Core invokes theme hooks *if present*: `SetStyle`, `SetScale`, `SetAlpha`,
   `OnInitialize`, `OnContextUpdate`, and `OnUpdate`. The parser additionally
   calls `OnActivateTheme`, and detects a multi-style theme by testing for
   `theme.SetStyle`. Hub's widget integration creates and updates widgets using
   each theme's `WidgetConfig`. These hooks are an optional-duck-typed
   contract; do not assume every theme defines every hook.

### Settings, UI, and persistence

- Core TOCs declare account-wide `NeatPlatesSettings` and per-character
  `NeatPlatesOptions`; Hub declares account-wide `NeatPlatesHubSettings`.
- `NeatPlatesPanel.lua` owns base addon settings and entry points.
  Hub's `Defaults.lua`, `Helpers.lua`, `Templates.lua`, and `Hub.lua` provide
  defaults, merging/helpers, controls, profile UI, and import/export.
  AceSerializer supports profile serialization; AceLocale supplies UI text.
- SavedVariables are restored after an addon's files execute, before its
  `ADDON_LOADED` notification. Respect the existing initialization handlers;
  do not assume persisted data is ready during top-level script execution.
- A setting change may require a default, UI control/menu entry, localization,
  profile merge or migration behavior, and a runtime consumer. Trace all of
  these rather than updating just the visible control.

### Existing development and automation

- Runtime libraries are vendored under `NeatPlates\libs` and were present in
  CE's initial snapshot. Upstream instead ignores `libs` in Git and fetches
  dependencies using `.pkgmeta` externals. Both approaches embed libraries in
  the player download; vendoring changes how sources are maintained, not how
  WoW gets them. CE's `.pkgmeta` deliberately declares **no externals** so
  packaging never fetches over the reviewed in-repo copies.
- TOC/XML embed lists load those libraries at runtime. `.pkgmeta` is a packager
  recipe, not a WoW manifest or runtime dependency downloader.
- `.editorconfig` is the shared text baseline: UTF-8, LF, final newline, and
  trailing-whitespace cleanup except in Markdown. `.gitattributes` enforces LF
  in the index, marks media as binary, and keeps `NeatPlates\libs` out of
  language stats and default diffs. Neither prescribes Lua indentation; follow
  the surrounding code.
- `.idea` and `.vscode` are local, ignored editor configuration. Developers
  configure Lua diagnostics and WoW API annotations locally; EditorConfig does
  not replace a language server, API definitions, or a Lua formatter.
- `.github\workflows\ci.yml` runs on every pull request and needs no secrets:
  manifest/XML integrity (`tools\validate_addon.py`), a stock Lua 5.1 parse of
  every non-vendored file, an advisory Luacheck pass, and a no-upload packager
  build published as a downloadable artifact.
- `.github\workflows\release.yml` is tag-driven. Without `CF_API_TOKEN` it
  builds and attaches the zip to a GitHub Release and skips third-party
  uploads, so it is safe to run before any credentials exist.
- `.luacheckrc` declares the project and Blizzard globals. The Luacheck job is
  intentionally non-blocking while the legacy warning backlog is worked down;
  new and changed code is still expected to be clean.
- There is still no automated test suite, and no project-wide formatter policy.
  The StyLua configuration inside a vendored library is not project policy.
- CI validates structure only. It cannot emulate Blizzard's protected UI,
  secret values, or any client flavor, so a green run never substitutes for the
  manual in-game checks described below.

### Known repository-state issues

These are current, verified facts about the repo, not roadmap items. Be aware
of them so a change does not quietly make them worse.

- Several addons ship both hyphenated and underscored manifests for the same
  flavor (for example `NeatPlates-Mainline.toc` and `NeatPlates_Mainline.toc`,
  and the Hub/Widgets equivalents). WoW accepts either separator, so these are
  parallel manifests with duplicated metadata and they have already drifted:
  the two core Mainline files differ in their `## Notes` line. When editing a
  file list, `## Interface`, or any metadata field, update every sibling
  manifest for that addon and flavor.
- `## Version` is now `@project-version@` in all 111 shipped manifests. The
  packager substitutes the Git tag at build time, so the suite ships one
  consistent version. Do not hand-edit these back to a literal version: running
  from a raw Git checkout will show the literal `@project-version@` in-game,
  which is expected for unpackaged source. `tools\validate_addon.py` enforces
  the keyword.
- The base (flavor-less) manifests disagree on `## Interface`: the twelve
  themes declare `120100` while `NeatPlates`, `NeatPlatesHub`, and
  `NeatPlatesWidgets` declare `50504`. Flavor-specific manifests exist for all
  supported clients, so this fallback rarely decides loading, but it is a real
  inconsistency. The validator reports it as a warning; resolve it deliberately
  rather than by bulk-editing untested Interface values.
- The Git index stores LF, while a Windows checkout typically has CRLF in the
  working tree. `.editorconfig` declares `end_of_line = lf`, and `.gitattributes`
  makes that normalization explicit for other contributors.
  Several `.toc` files are UTF-8 with BOM even though `.editorconfig` specifies
  plain `utf-8`. An editor that aggressively applies EditorConfig can therefore
  rewrite an entire legacy file on first touch. Keep diffs to the lines you
  actually changed, and never mix a whitespace/encoding normalization with a
  behavior change in the same commit.
- Complexity is concentrated in a few large, non-vendored files:
  `NeatPlatesCore.lua` (~2.9k lines), `NeatPlatesUtility.lua` (~2.2k),
  `NeatPlatesPanel.lua` (~1.5k), `NeatPlatesHub\Templates.lua` (~1.4k), and
  `NeatPlatesHub\Hub.lua` (~1.2k). Read the surrounding region before editing
  these; they are the most likely place for an unintended interaction.

## Working rules for the current codebase

- Understand the real load path and callers before editing. Reuse existing
  helpers and APIs; avoid new dependencies, frameworks, or abstractions unless
  the requested behavior needs them.
- Fix root causes in the appropriate shared layer rather than copying a fix
  into every theme. Keep changes focused; avoid unrelated cleanup or sweeping
  formatting changes.
- Prefer local helpers and addon-private state. New globals should be deliberate
  cross-addon contracts, not accidental assignments. Preserve existing public
  globals and callback signatures unless a coordinated migration is requested.
- Check affected flavor manifests and XML include chains when adding or moving
  files. Preserve dependency declarations, asset paths, and path casing.
  Do not bump Interface versions for clients that have not been verified.
- Reuse the client flags and check API availability where appropriate. Keep
  intentional client-specific behavior; do not assume Classic and Retail APIs
  or return values are interchangeable.
- Modern clients can return secret values. Do not perform Lua comparisons,
  arithmetic, concatenation, or table indexing on potentially secret values
  without a permitted path. Follow existing guards (`issecretvalue` and the
  local `IsSecretValue` wrappers) and supported Blizzard sinks such as
  `FontString:SetFormattedText` and `Texture:SetAlphaFromBoolean`; never try to
  extract restricted data or bypass combat protections. These guards are not
  confined to core: equivalent handling exists in `NeatPlatesHub\functions`
  (Core, Color, Text), several widgets, and at least one theme. A value that is
  safe where it is produced can become unsafe where another addon consumes it,
  so trace a changed value across the addon boundary it crosses.
- Respect combat lockdown and protected frame restrictions. Review changes to
  anchoring, visibility, click-through behavior, and CVars in and out of combat.
- Nameplates are recycled. Review event registrations, timers, callbacks, and
  widget cleanup on hide/removal/reset to avoid stale unit state or leaks.
  Avoid adding allocations or unbounded work in per-frame/per-plate hot paths.
- Preserve stored profiles, including explicit `false` values. Use existing
  default/merge helpers and deliberate migrations rather than resetting data.
- Use the existing localization pattern for user-facing text. Preserve license
  notices when changing or packaging vendored code and media.
- Keep comments focused on non-obvious constraints. Update directly related
  documentation when behavior changes; do not create unsolicited planning,
  summary, or how-to files.

### Validation today

Use any relevant checks available for the changed area and report their limits.
Documentation-only changes do not require an in-game run.

Before opening a pull request, run the structural check locally (no third-party
dependencies, Python 3 only):

```
python tools/validate_addon.py
```

Errors fail CI; warnings are informational. This verifies manifests, include
chains, and file casing. It proves nothing about runtime behavior.

For runtime changes, manual verification is still needed on affected supported
clients:

- Load with fresh settings and with an existing profile; open `/np` and verify
  that changed settings survive `/reload`.
- Check affected themes and widgets, target changes, and repeated nameplate
  appearance/removal, both friendly and hostile where relevant.
- Exercise the changed behavior in and out of combat. For restricted-data
  changes, include actual combat rather than only an idle-world check.
- Check for Lua errors, taint/protected-action failures, visual regressions, and
  stale state. State which clients/scenarios were actually tested; if WoW is
  unavailable, say that in-game behavior remains unverified.

## Roadmap: desired architecture and tooling

Items marked **Done** are implemented; everything else is a proposal, not
permission to expand a task.

These are incremental goals for a small team, not a mandate for a rewrite.
Preserve the addon folder split and existing user experience unless a concrete
requirement justifies changing them.

### Architecture goals

- Evolve toward: WoW APIs/events -> compatibility adapters -> state and policy
  functions -> theme/widget rendering, with profiles supplying configuration.
  This is a responsibility split, not a requirement for new folders or classes.
- Consolidate repeated client/API compatibility logic into small shared helpers
  when touching the affected code. Do not build a speculative universal wrapper.
- Distinguish game rules/content from engine capabilities. Forever can combine
  older content with modern APIs; avoid extending the overloaded
  `NEATPLATES_IS_RETAIL` flag to unrelated decisions. Prefer specific API
  availability checks and verified event support where appropriate.
- Separate calculations, filtering, and profile migrations from frame mutation
  where practical so those rules can be tested without a running WoW client.
  Do not force secret runtime values into ordinary testable data models.
- Keep theme-specific artwork/layout in themes and common behavior in Hub.
  Gradually reduce core-to-Hub coupling and document the cross-addon contracts.
- Prefer functions, tables, private namespaces, and explicit collaborators over
  a class framework, dependency-injection container, or wholesale MVC rewrite.
  Introduce lifecycle/cleanup ownership and saved-data schema migrations where
  concrete changes require them.
- Make widget creation, settings refresh, unit assignment/removal, and
  enable/disable ownership explicit. Create required frames before subscribing
  to events; account for inactive recycled plates and cancel timers/subscriptions
  during cleanup. Evolve existing hooks rather than immediately adding a framework
  or general event bus.
- Consolidate CVar access and combat deferral incrementally. Decide explicitly
  which values the addon owns and when backups should be restored, without
  overwriting later player or addon changes.
- Add opt-in compatibility diagnostics when needed: client identification,
  relevant API/event availability, and widget state. Successful registration
  alone does not prove an event fires or a protected operation is allowed.

### Short-term CI goals

Items 1 and 2 are implemented; see "Existing development and automation" above.
Items 3 to 5 remain proposals.

1. **Done.** `tools\validate_addon.py` checks TOC/XML integrity and
   `ci.yml` adds a stock Lua 5.1 parse. Two traps it already handles, and which
   any replacement must keep handling: paths are relative to the manifest that
   declares them, and vendored libraries carry their own `.toc` files that WoW
   never loads as addons (for example
   `libs\LibButtonGlow-1.0\LibButtonGlow-1.0.toc` references `LibStub\LibStub.lua`,
   which is correct in its own context and must not be "fixed"). Syntax success
   is not runtime compatibility.
2. **Done, advisory.** `.luacheckrc` declares WoW and project globals, and the
   Luacheck job runs non-blocking. To finish the rollout: work the legacy
   warning backlog down, keep undefined-global detection useful rather than
   disabling it wholesale, then make the job blocking. Require changed and new
   code not to add issues in the meantime.
3. Agree on project-wide [StyLua](https://github.com/JohnnyMorganz/StyLua)
   configuration before enforcing formatting. Separate mechanical adoption
   from behavior changes. Exclude vendored libraries from our lint/style policy.
4. Add focused [Busted](https://lunarmodules.github.io/busted/) tests for isolated
   logic as it is changed or extracted, using small WoW API stubs where needed.
   Prioritize profile/default handling and regression cases over coverage quotas.
5. Validate literal localization keys used by project code against
   `NeatPlates\locales\enUS.lua`. Missing base keys should fail validation;
   incomplete community translations should be informational. Account for
   dynamic keys and exclude vendored code. This fits naturally as another check
   inside `tools\validate_addon.py`.

Keep checks reproducible outside any particular editor. Pin tool versions and
third-party Actions appropriately. CI cannot emulate Blizzard's protected UI,
secret values, or every client flavor; retain manual smoke checks.

### Packaging and release goals

- **Done.** [BigWigsMods/packager](https://github.com/BigWigsMods/packager) is
  adopted via `.pkgmeta`. `move-folders` lifts all 15 addon folders to the ZIP
  root so players extract siblings into `Interface\AddOns`; development files
  are excluded and `release.sh` copies `LICENSE` into each addon folder.
  Upstream's `.pkgmeta` was the layout reference; CE declares **no externals**
  so packaging never fetches over the vendored libraries. Record library
  sources and revisions in focused commits and document any local patches. A
  future switch to fetched dependencies should pin revisions and provide a
  reproducible local setup.
- **Remaining before the first packaged release:** nothing in this repository
  forces these, so verify them by hand.
  1. Download the `neatplates-package` artifact from a CI run, extract it, and
     confirm the ZIP root contains the 15 sibling folders and no development
     files.
  2. Install that artifact into a real `Interface\AddOns` and confirm the
     in-game version string shows the tag rather than `@project-version@`.
  3. Add `## X-Curse-Project-ID: <id>` to the core TOC files so uploads land on
     the correct CurseForge page, then add `CF_API_TOKEN` as an Actions secret.
  4. Resolve the base-manifest `## Interface` disagreement noted above.
  Verify manifest selection and flavor metadata before claiming compatibility.
  A single distribution can contain multiple addon folders; it does not require
  a separate CurseForge project for every theme.
- Publish version tags through the gated `release.yml` workflow. Store tokens
  only in Actions secrets and grant minimal workflow permissions. Pull-request
  CI must never need publishing credentials, and currently does not.
- Reviewer builds are downloadable workflow artifacts, not automatic public
  releases. Introduce reusable channel-specific release workflows only when
  needed, keeping packaging consistent across channels.
- Keep release notes, TOC versions, client compatibility declarations, and
  profile migration behavior consistent. Never publish an untested flavor
  solely because a matching historical TOC exists.
