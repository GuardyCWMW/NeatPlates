#!/usr/bin/env python3
"""Unpack the distribution ZIP for a single-extraction Actions artifact."""

import argparse
from pathlib import Path, PurePosixPath
from zipfile import ZipFile


def prepare_artifact(package_dir: Path, destination: Path) -> None:
    packages = sorted(package_dir.glob("*.zip"))
    if len(packages) != 1:
        raise ValueError(f"Expected exactly one package ZIP in {package_dir}, found {len(packages)}")

    repo = Path(__file__).resolve().parent.parent
    addons = {
        folder.name for folder in repo.glob("NeatPlates*")
        if folder.is_dir() and (folder / f"{folder.name}.toc").is_file()
    }
    with ZipFile(packages[0]) as package:
        names = set(package.namelist())
        roots = set()
        for name in names:
            path = PurePosixPath(name)
            if path.is_absolute() or ".." in path.parts or "\\" in name or ":" in name:
                raise ValueError(f"Invalid package path: {name}")
            roots.add(path.parts[0])
        if roots != addons:
            raise ValueError(
                f"Package layout mismatch: missing {sorted(addons - roots)}, "
                f"unexpected {sorted(roots - addons)}"
            )
        for addon in sorted(addons):
            for required in (f"{addon}/{addon}.toc", f"{addon}/LICENSE"):
                if required not in names or package.getinfo(required).is_dir():
                    raise ValueError(f"Package is missing {required}")

        destination.mkdir(parents=True, exist_ok=False)
        package.extractall(destination)
    print(f"Prepared {len(addons)} sibling addon folders from {packages[0]} in {destination}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("destination", type=Path)
    parser.add_argument("--package-dir", type=Path, default=Path(".release"))
    args = parser.parse_args()
    try:
        prepare_artifact(args.package_dir, args.destination)
    except ValueError as error:
        parser.exit(1, f"error: {error}\n")
