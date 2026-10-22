# NeatPlates Community Edition

NeatPlates Community Edition (CE) is a community-maintained continuation of
[NeatPlates by Luxocracy](https://www.curseforge.com/wow/addons/neatplates),
which builds on the original Tidy Plates project.

NeatPlates enhances enemy, friendly, and target nameplates with customizable
themes, colors, threat information, auras, cast information, and other useful
combat details. CE focuses on compatibility, stability, performance, and
preserving the familiar NeatPlates appearance and behavior.

Download [Community Edition on CurseForge](https://www.curseforge.com/wow/addons/neatplates-community-edition-mop-classic).
For version-specific changes, see the [changelog](NeatPlates/CHANGELOG.md).

## Supported WoW Versions

NeatPlates Community Edition keeps the original NeatPlates experience working
across current World of Warcraft clients:

- World of Warcraft: Forever 1.60.1+
- Retail 12.1+
- Mists of Pandaria Classic Phase 5+
- TBC Anniversary 2.5.6+
- Classic Era 1.15.9+

Feature availability varies by client. Use a release explicitly intended for
your client and check its release notes for known limitations; an Interface
version alone does not guarantee that every feature is available.

## Installation

1. Download a compatible release from the
   [CE CurseForge page](https://www.curseforge.com/wow/addons/neatplates-community-edition-mop-classic).
2. Extract all included addon folders into your client's `Interface\AddOns`
   directory. Folders such as `NeatPlates`, `NeatPlatesHub`,
   `NeatPlatesWidgets`, and the themes must be siblings, not nested inside a
   repository or release folder.
3. Enable NeatPlates, Hub, Widgets, and the themes you want in the in-game
   AddOns list.

CE replaces the original NeatPlates installation: it uses the same addon folder
and SavedVariables names. Back up your existing addon folders and
`WTF\Account` settings before switching; do not install both versions side by
side. Libraries are included in the package and do not need separate downloads.

If WoW reports the addon as out of date, check the release's client compatibility
before enabling it anyway. GitHub source archives are not a substitute for a
packaged release.

## Configuration

- Open the Blizzard AddOn options and select NeatPlates.
- Use `/np` or `/neatplates` to open the NeatPlates options directly.
- Use `/hub` to open the shared theme/profile configuration.
- Configure nameplate themes, colors, threat display, auras, cast bars, and
  other visual settings for the active profile.

Existing NeatPlates profiles remain available while the Community Edition
adapts the addon to current Blizzard UI and nameplate APIs.

## Reporting Bugs

Please check [existing issues](https://github.com/GuardyCWMW/NeatPlates/issues)
before opening a new report. Include:

- WoW client, version/build, and NeatPlates CE version.
- Active theme and relevant settings.
- Steps to reproduce, expected behavior, and actual behavior.
- Relevant Lua errors and screenshots, where useful.
- Whether it happens in combat and whether it persists with unrelated addons
  disabled.

Report CE issues in this repository rather than the original project's tracker.

## Contributing and Development

Bug reports, testing, documentation, and focused code contributions are welcome.
Discuss substantial changes in an issue first, and describe the affected clients
and verification performed in pull requests.

Every pull request runs automated structural checks: manifest and XML integrity,
a Lua 5.1 syntax parse, an advisory lint pass, and a packaged build you can
download from the run's artifacts to test in game. You can run the structural
check yourself with Python 3 and no other dependencies:

```
python tools/validate_addon.py
```

These checks validate structure only. The addon runs inside WoW's Lua
environment, so actual UI behavior still needs in-game testing on affected
clients.

With Lua 5.1 installed, run `lua tools\test_castbar.lua` from the repository root
for focused cast-bar regression checks using stubbed WoW APIs. These cover
duration styles, native timers, readable/secret values, and spell-target updates,
including direct formatting of protected duration values. CI runs these checks;
they do not emulate Blizzard's protected runtime.
The checks also cover class-coloured spell targets without Blizzard's legacy
colour formatter and party-aggro name colours through both name-update paths.
Roth checks cover cast-fill texture cropping, locale fonts, non-overlapping
cast labels, and consistent name-only positioning. Roth uses its dedicated
cast-fill artwork, with the spell name and target below the bar and the timer
inside it; Russian uses the client font instead of the Latin-only decorative font.

See [AGENTS.md](AGENTS.md) for the current architecture, contribution guidance,
manual validation, and proposed architecture, CI, and release improvements.
Shared text conventions live in `.editorconfig` and `.gitattributes`; IDE
settings remain local.

## Credits

Original projects:

- [NeatPlates](https://www.curseforge.com/wow/addons/neatplates) by Luxie /
  Luxocracy ([original source](https://github.com/Luxocracy/NeatPlates))
- Tidy Plates by danltiger and CynthiaV

Thank you to the original authors, past maintainers, and community contributors
for their code, artwork, translations, testing, and bug reports.

## License

NeatPlates Community Edition is based on NeatPlates and Tidy Plates and is
distributed under the MIT License. See [LICENSE](LICENSE) for the complete
license text and attribution notices.

Bundled third-party libraries retain their own copyright and license notices.

## Disclaimer

NeatPlates Community Edition is an unofficial community-maintained version and
is not affiliated with Blizzard Entertainment or the original authors.
