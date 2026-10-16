#!/usr/bin/env python3
"""Static validation for the NeatPlates addon suite.

Runs with no third-party dependencies so it works locally and in CI.

Checks performed:
  1. Every file referenced by a loadable TOC or XML include exists, with
     matching case (WoW on Linux/macOS is case-sensitive; Windows hides this).
  2. XML <Include>/<Script> chains resolve recursively, relative to the file
     that declares them.
  3. Sibling manifests for the same addon+flavor (the hyphen and underscore
     variants, e.g. NeatPlates-Mainline.toc / NeatPlates_Mainline.toc) agree on
     Interface, file list, SavedVariables and Dependencies.
  4. Every shipped addon declares "## Version: @project-version@" so the
     packager stamps one consistent version across the suite.
  5. "## Dependencies" / "## OptionalDeps" name addon folders that exist.

Deliberately NOT checked: vendored libraries under NeatPlates/libs. They carry
their own .toc files that WoW never loads as addons, and their internal paths
are correct in their own packaging context.

Usage:
    python tools/validate_addon.py [--github]

Exit code is non-zero if any error is found. Warnings never fail the build.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

VENDORED = ("libs",)
VERSION_KEYWORD = "@project-version@"

# Flavor suffixes WoW recognizes, lowercased. WoW accepts either "-" or "_"
# as the separator, which is why this repo has parallel manifests.
FLAVORS = {
    "mainline", "standard", "classic", "vanilla", "tbc", "bcc", "wrath",
    "wotlkc", "cata", "mists", "camelot",
}

# Inline TOC directives such as "File.lua [AllowLoadGameType classic]".
INLINE_DIRECTIVE = re.compile(r"\[[^\]]*\]")
XML_REF = re.compile(r"""<(?:Script|Include)\s+file\s*=\s*["']([^"']+)["']""", re.I)


class Findings:
    def __init__(self) -> None:
        self.errors: list[tuple[str, str]] = []
        self.warnings: list[tuple[str, str]] = []
        self._seen: set[tuple[str, str]] = set()

    def error(self, where: str, msg: str) -> None:
        # The same XML chain is reachable from many TOCs; report each issue once.
        if (where, msg) not in self._seen:
            self._seen.add((where, msg))
            self.errors.append((where, msg))

    def warn(self, where: str, msg: str) -> None:
        if (where, msg) not in self._seen:
            self._seen.add((where, msg))
            self.warnings.append((where, msg))


def is_vendored(path: Path) -> bool:
    return any(part in VENDORED for part in path.relative_to(REPO).parts)


def read_text(path: Path) -> str:
    """Read a manifest, tolerating the UTF-8 BOM several TOC files carry."""
    return path.read_bytes().decode("utf-8-sig", errors="replace")


def resolve_case_sensitive(base: Path, relative: str) -> Path | None:
    """Resolve `relative` under `base`, requiring exact case at each level.

    Returns the resolved path, or None if any component is missing or differs
    only by case.
    """
    current = base
    parts = [p for p in relative.replace("\\", "/").split("/") if p not in ("", ".")]
    for part in parts:
        if part == "..":
            current = current.parent
            continue
        try:
            entries = {e.name for e in current.iterdir()}
        except (NotADirectoryError, FileNotFoundError, PermissionError):
            return None
        if part not in entries:
            return None
        current = current / part
    return current


def parse_toc(path: Path) -> tuple[dict[str, str], list[str]]:
    """Return (directives, file-list) for a TOC."""
    directives: dict[str, str] = {}
    files: list[str] = []
    for line in read_text(path).splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.startswith("##"):
            key, _, value = stripped[2:].partition(":")
            directives[key.strip()] = value.strip()
        elif stripped.startswith("#"):
            continue  # plain comment
        else:
            entry = INLINE_DIRECTIVE.sub("", stripped).strip()
            if entry:
                files.append(entry)
    return directives, files


def check_xml(xml_path: Path, findings: Findings, seen: set[Path]) -> None:
    """Recursively validate <Include>/<Script> references inside an XML file."""
    if xml_path in seen:
        return
    seen.add(xml_path)

    rel_label = xml_path.relative_to(REPO).as_posix()
    for ref in XML_REF.findall(read_text(xml_path)):
        # XML references are relative to the directory of the declaring file.
        target = resolve_case_sensitive(xml_path.parent, ref)
        if target is None or not target.is_file():
            findings.error(rel_label, f"references missing file: {ref}")
            continue
        if target.suffix.lower() == ".xml":
            check_xml(target, findings, seen)


def flavor_of(toc: Path) -> str:
    """Return the normalized flavor for a TOC, or '' for the base manifest."""
    stem = toc.stem
    for sep in ("-", "_"):
        _, found, suffix = stem.rpartition(sep)
        if found and suffix.lower() in FLAVORS:
            return suffix.lower()
    return ""


def addon_dirs() -> list[Path]:
    return sorted(
        d for d in REPO.iterdir()
        if d.is_dir() and not d.name.startswith(".") and any(d.glob("*.toc"))
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--github", action="store_true",
                        help="emit GitHub Actions annotations")
    args = parser.parse_args()

    findings = Findings()
    addons = addon_dirs()
    addon_names = {d.name for d in addons}
    # addon -> flavor -> Interface, used for the cross-addon consistency check.
    interfaces: dict[str, dict[str, str]] = {}

    if not addons:
        print("No addon folders found - is the script in tools/?", file=sys.stderr)
        return 2

    toc_count = 0
    for addon in addons:
        # Group manifests by flavor so sibling variants can be compared.
        by_flavor: dict[str, list[Path]] = {}

        for toc in sorted(addon.rglob("*.toc")):
            if is_vendored(toc):
                continue
            toc_count += 1
            rel_label = toc.relative_to(REPO).as_posix()
            directives, files = parse_toc(toc)
            by_flavor.setdefault(flavor_of(toc), []).append(toc)
            interfaces.setdefault(addon.name, {})[flavor_of(toc)] = (
                directives.get("Interface", "")
            )

            # 4. Version keyword
            version = directives.get("Version", "")
            if not version:
                findings.error(rel_label, "missing '## Version:' directive")
            elif version != VERSION_KEYWORD:
                findings.error(
                    rel_label,
                    f"'## Version: {version}' should be "
                    f"'## Version: {VERSION_KEYWORD}' so the packager stamps it",
                )

            # 5. Dependencies reference real addon folders.
            # Only in-suite "NeatPlates*" names are errors: OptionalDeps
            # legitimately names external addons that ship separately, such as
            # the NeatPlatesHub<locale> translation packs.
            for key in ("Dependencies", "RequiredDeps", "OptionalDeps"):
                raw = directives.get(key, "")
                for dep in (d.strip() for d in raw.split(",")):
                    if not dep or dep in addon_names:
                        continue
                    if key == "OptionalDeps":
                        continue  # optional and often external by design
                    if dep.startswith("NeatPlates"):
                        findings.error(
                            rel_label,
                            f"'## {key}' requires missing in-suite addon: {dep}",
                        )
                    else:
                        findings.warn(
                            rel_label,
                            f"'## {key}' names external addon: {dep}",
                        )

            # 1 + 2. Referenced files exist, XML chains resolve
            seen_xml: set[Path] = set()
            for entry in files:
                target = resolve_case_sensitive(addon, entry)
                if target is None or not target.is_file():
                    findings.error(
                        rel_label,
                        f"lists missing file (or case mismatch): {entry}",
                    )
                    continue
                if target.suffix.lower() == ".xml":
                    check_xml(target, findings, seen_xml)

        # 3. Sibling manifest agreement
        for flavor, tocs in sorted(by_flavor.items()):
            if len(tocs) < 2:
                continue
            label = flavor or "(base)"
            reference = tocs[0]
            ref_directives, ref_files = parse_toc(reference)
            ref_label = reference.relative_to(REPO).as_posix()
            for other in tocs[1:]:
                other_directives, other_files = parse_toc(other)
                other_label = other.relative_to(REPO).as_posix()
                pair = f"{ref_label} vs {other_label}"
                if ref_files != other_files:
                    findings.error(
                        other_label,
                        f"file list differs from sibling {label} manifest "
                        f"({pair}); WoW may load either one",
                    )
                for key in ("Interface", "SavedVariables",
                            "SavedVariablesPerCharacter", "Dependencies"):
                    if ref_directives.get(key, "") != other_directives.get(key, ""):
                        findings.error(
                            other_label,
                            f"'## {key}' differs from sibling {label} manifest: "
                            f"'{ref_directives.get(key, '')}' vs "
                            f"'{other_directives.get(key, '')}' ({pair})",
                        )
                for key in ("Title", "Notes"):
                    if ref_directives.get(key, "") != other_directives.get(key, ""):
                        findings.warn(
                            other_label,
                            f"'## {key}' differs from sibling {label} manifest",
                        )

    # 6. Cross-addon Interface agreement per flavor. The suite loads together,
    # so a theme declaring a different client version than core will be flagged
    # out of date (or silently skipped) on that client.
    flavor_labels = {f for per_flavor in interfaces.values() for f in per_flavor}
    for flavor in sorted(flavor_labels):
        seen: dict[str, list[str]] = {}
        for addon_name, per_flavor in interfaces.items():
            if flavor in per_flavor:
                seen.setdefault(per_flavor[flavor], []).append(addon_name)
        if len(seen) > 1:
            label = flavor or "(base)"
            detail = "; ".join(
                f"'{iface}': {', '.join(sorted(names))}"
                for iface, names in sorted(seen.items())
            )
            findings.warn(
                "(suite)",
                f"addons disagree on '## Interface' for the {label} manifest -> "
                f"{detail}",
            )

    # Report
    for where, msg in findings.warnings:
        if args.github:
            print(f"::warning file={where}::{msg}")
        else:
            print(f"WARN  {where}: {msg}")
    for where, msg in findings.errors:
        if args.github:
            print(f"::error file={where}::{msg}")
        else:
            print(f"ERROR {where}: {msg}")

    print(
        f"\nChecked {toc_count} manifests across {len(addons)} addons: "
        f"{len(findings.errors)} error(s), {len(findings.warnings)} warning(s)."
    )
    return 1 if findings.errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
