<!--
Thanks for contributing to NeatPlates Community Edition.

CI checks structure only: manifests, Lua syntax, and that the package builds.
It cannot emulate Blizzard's protected UI, secret values, or any client flavor,
so the in-game notes below are the part reviewers actually rely on.
-->

## What does this change?

<!-- A short summary, and the issue it fixes (e.g. "Fixes #123"). -->

## Why?

<!-- The underlying problem. For behavior changes, note anything users will see differently. -->

## Clients affected

<!-- Mark every client this change can reach. -->

- [ ] Forever
- [ ] Retail
- [ ] MoP Classic
- [ ] TBC Anniversary
- [ ] Classic Era
- [ ] Documentation / tooling only (no runtime impact)

## Testing performed

<!--
State which clients you ACTUALLY launched and what you exercised. If WoW was
unavailable, say so plainly - "unverified in game" is a useful, honest answer
and far better than implying coverage that does not exist.
-->

- Clients tested:
- Themes tested:
- Scenarios:

## Checklist

- [ ] I understood the real load path (TOC / XML include chain) before editing.
- [ ] Changes are focused; no unrelated cleanup or sweeping reformatting.
- [ ] No whitespace or line-ending normalization mixed into a behavior change.
- [ ] Touched every sibling flavor manifest if I changed a file list or metadata.
- [ ] Existing public globals and callback signatures are preserved.
- [ ] Saved profiles still load, including explicit `false` values.
- [ ] User-facing text uses the existing localization pattern (`enUS.lua` base key added).
- [ ] Checked for Lua errors, taint, and stale state on recycled nameplates.
- [ ] Vendored code under `NeatPlates/libs` is unchanged, or the reason is explained below.

## Notes for reviewers

<!-- Anything non-obvious: constraints, trade-offs, or follow-up work. -->
