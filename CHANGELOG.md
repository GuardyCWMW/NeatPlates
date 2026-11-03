# NeatPlates

## Unreleased

- Fixed Forever Lua errors when class-colouring spell targets or interrupt attribution by using an addon-owned colour formatter. Fixed party-aggro name colouring returning a table instead of numeric RGBA values.
- Fixed duration text remaining blank for secret cast timestamps on Forever/Retail by formatting Blizzard duration objects directly, and cleared timer references on cast/plate cleanup.
- Restored cast-bar spell targets and duration styles on Forever when the client supplies readable values, retaining native timer handling for secret cast times on modern clients.
- Centered Forever's adjustable click area on the theme's health bar instead of the underlying Blizzard frame, preserving saved dimensions and stable bounds during hover enlargement. Name-only plates retain their previous placement.
- Fixed Forever nameplate clicking and mouseover areas using the client's per-plate hit-test API instead of unavailable legacy sizing APIs. Clickable width/height, display offsets, and friendly/enemy click-through now apply to the real hitbox, independently of target/mouseover enlargement; the green preview follows those bounds.

## v468-ce7.5.1

- Added a project-level MIT license with attribution for the original NeatPlates and Tidy Plates projects.
- Added an updated README covering supported WoW versions, configuration, credits, licensing, and repository information.

## v468-ce7.5

- Restored the Threat Percentage widget on Retail and Forever using the modern `UnitDetailedThreatSituation` API.
- Added secret-safe threat percentage rendering without inspecting or transforming protected combat values in Lua.
- Kept the existing threat percentage implementation unchanged for Classic, TBC, and Mists of Pandaria clients.

## v468-ce7.4

- Optimized critical nameplate update paths by avoiding redundant Blizzard frame traversal, full refreshes for alpha-only changes, repeated callback allocation, and repeated custom-color parsing.
- Added secret-safe health-based coloring for Retail and Forever using Blizzard's supported curve APIs.
- Added secret-safe low-health opacity highlighting for Retail and Forever, passing protected opacity values directly to the UI without inspecting them in Lua.

## v468-ce5

- Added a dedicated Stacking Nameplates section to the main NeatPlates options panel.
- Added a localized notice explaining that actual nameplate stacking is controlled by Blizzard's Nameplate settings in MoP Classic Phase 5+.
- Added a Spacing Offset slider for Blizzard's `nameplateOverlapV` CVar, with deferred application after combat when needed.
- Added Display Offset X and Display Offset Y sliders to move the NeatPlates overlay relative to Blizzard's real nameplate anchor.
- Added visible live value readouts for the new stacking-related sliders.
- Added localization keys for the new stacking options, with German translations and safe fallback text for other locales.

## v468-ce4

- Fixed nameplate stacking/spreading in MoP Classic Phase 5 by keeping Blizzard's nameplate UnitFrame active as the layout anchor while NeatPlates draws the visible plate.
- Updated NeatPlates to follow Blizzard's nameplate stacking behavior instead of overriding it internally.
- Replaced the NeatPlates stacking checkbox with a localized notice explaining that stacking is now controlled through Blizzard's Nameplate settings.

## v468-ce3

- Added a custom NeatPlates addon icon and assigned it to the visible NeatPlates modules in the addon list.
- Fixed an instance-related nil CVar issue when restoring Blizzard nameplate sizing for default Blizzard nameplates.
- Fixed the Slim Vertical theme failing to render nameplates when a legacy WoW font object name such as `GameFontWhite` was passed through the font setup path.

## [v468](https://github.com/Luxocracy/NeatPlates/tree/v468) (2025-09-21)
[Full Changelog](https://github.com/Luxocracy/NeatPlates/compare/v467...v468) [Previous Releases](https://github.com/Luxocracy/NeatPlates/releases)

- Use default blizzard plates for "softinteract" units, as these are usually inanimate objects with special nameplates  

## v468-ce2

- Added a new profile option: Ignore Blizzard Alpha.
When enabled, NeatPlates uses its own profile opacity values directly instead of multiplying them with Blizzard’s nameplate alpha.
This helps prevent non-target nameplates from appearing partially transparent even when Non-Target Opacity is set to 100%.
- Added localized text entries for the new option and tooltip.
- Updated MoP Classic TOC metadata to v468-ce2.

## v468-ce1

- Basic functionality and operability of NeatPlates for MoP Phase 5 have been restored
