"""Create a private run directory and prepare a Korean text for Pi."""

from __future__ import annotations

import argparse
from datetime import date
from pathlib import Path
import secrets
import sys

import prepare_monolith_input


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Prepare a Humanize Korean run")
    parser.add_argument("input", type=Path, help="UTF-8 input text file")
    parser.add_argument(
        "--genre",
        default="essay",
        choices=("essay", "column", "report", "blog", "abstract", "public"),
    )
    parser.add_argument("--workspace", type=Path, default=Path("_workspace"))
    args = parser.parse_args(argv)

    source = args.input.expanduser().resolve()
    if not source.is_file():
        parser.error(f"input file not found: {source}")
    try:
        raw = source.read_bytes()
        original = raw.decode("utf-8-sig")
    except (OSError, UnicodeError) as exc:
        parser.error(f"could not read UTF-8 input: {exc}")
    if not original.strip():
        parser.error("input file is empty")

    workspace = args.workspace.expanduser().resolve()
    workspace.mkdir(parents=True, exist_ok=True)
    today = date.today().isoformat()
    run_dir = None
    for index in range(1, 1000):
        candidate = workspace / f"{today}-{index:03d}-{secrets.token_hex(2)}"
        try:
            candidate.mkdir()
            run_dir = candidate
            break
        except FileExistsError:
            continue
    if run_dir is None:
        parser.error("no free run directory")

    (run_dir / "00_original_raw.txt").write_bytes(raw)
    (run_dir / "01_input.txt").write_text(original, encoding="utf-8")
    result = prepare_monolith_input.main(
        ["--run-dir", str(run_dir), "--genre", args.genre]
    )
    print(f"run_dir={run_dir}")
    return result


if __name__ == "__main__":
    sys.exit(main())
