#!/usr/bin/env python3
"""Build a standalone, offline Pi skill ZIP from the repository sources."""

from __future__ import annotations

import argparse
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo


ROOT = Path(__file__).resolve().parent.parent
VERSION = "2.4.1"
SKILL = "humanize-korean"
SCRIPT_NAMES = (
    "checks.py",
    "console.py",
    "local_runner.py",
    "prepare_monolith_input.py",
    "reassemble_chunks.py",
    "restore_modality.py",
    "sanitize_text.py",
    "verify_gates.py",
)


def collect_files() -> dict[str, Path]:
    files = {
        f"{SKILL}/SKILL.md": ROOT / "packaging" / "pi" / "SKILL.md",
        f"{SKILL}/LICENSE": ROOT / "LICENSE",
        f"{SKILL}/scripts/start_run.py": ROOT / "packaging" / "pi" / "start_run.py",
        "INSTALL.txt": ROOT / "packaging" / "pi" / "INSTALL.txt",
    }
    for name in SCRIPT_NAMES:
        files[f"{SKILL}/scripts/{name}"] = ROOT / "scripts" / name

    # The original scripts resolve metrics from this repository-shaped path.
    refs = ROOT / "skills" / SKILL / "references"
    for source in refs.rglob("*"):
        if source.is_file() and source.suffix in {".md", ".json", ".py"}:
            relative = source.relative_to(ROOT).as_posix()
            files[f"{SKILL}/{relative}"] = source
    return files


def build(output: Path) -> tuple[int, int]:
    files = collect_files()
    missing = [str(path) for path in files.values() if not path.is_file()]
    if missing:
        raise FileNotFoundError("missing package files: " + ", ".join(missing))
    output.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(output, "w", compression=ZIP_DEFLATED, compresslevel=9) as archive:
        for name, source in sorted(files.items()):
            entry = ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            entry.compress_type = ZIP_DEFLATED
            entry.external_attr = 0o644 << 16
            archive.writestr(entry, source.read_bytes(), compress_type=ZIP_DEFLATED, compresslevel=9)
    return len(files), output.stat().st_size


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output",
        type=Path,
        default=ROOT / "dist" / f"pi-{SKILL}-v{VERSION}.zip",
    )
    args = parser.parse_args()
    count, size = build(args.output)
    print(f"{args.output.resolve()} ({count} files, {size} bytes)")


if __name__ == "__main__":
    main()
