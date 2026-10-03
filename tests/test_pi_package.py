"""The released Pi ZIP must work after extraction outside this repository."""

from __future__ import annotations

import json
from pathlib import Path
import subprocess
import sys
from tempfile import TemporaryDirectory
import unittest
from zipfile import ZipFile


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import build_pi_skill  # noqa: E402


class PiPackageTests(unittest.TestCase):
    def test_extracted_package_scores_and_verifies(self) -> None:
        skill_version = (
            (ROOT / "skills/humanize-korean/SKILL.md")
            .read_text(encoding="utf-8")
            .split("version: \"", 1)[1]
            .split('"', 1)[0]
        )
        self.assertEqual(build_pi_skill.VERSION, skill_version)

        with TemporaryDirectory() as temp:
            root = Path(temp)
            archive = root / "skill.zip"
            build_pi_skill.build(archive)
            with ZipFile(archive) as zip_file:
                self.assertIsNone(zip_file.testzip())
                self.assertFalse(any("__pycache__" in name for name in zip_file.namelist()))
                zip_file.extractall(root)

            skill = root / "humanize-korean"
            self.assertTrue((skill / "SKILL.md").is_file())
            input_path = root / "input.txt"
            input_path.write_text(
                "오늘 회의에서는 새 일정과 예산을 논의했다. 다음 회의는 금요일에 열린다.\n",
                encoding="utf-8",
            )
            started = subprocess.run(
                [sys.executable, str(skill / "scripts/start_run.py"), str(input_path),
                 "--workspace", str(root / "workspace")],
                capture_output=True,
                text=True,
                encoding="utf-8",
                check=False,
            )
            self.assertEqual(started.returncode, 0, started.stdout + started.stderr)
            run_dir = next((root / "workspace").iterdir())
            self.assertEqual((run_dir / "00_original_raw.txt").read_bytes(), input_path.read_bytes())
            metrics = json.loads((run_dir / "00_metrics.json").read_text(encoding="utf-8"))
            self.assertIn(metrics["route_hint"], {"light", "standard", "heavy"})

            (run_dir / "final.md").write_text(
                (run_dir / "01_input.txt").read_text(encoding="utf-8"), encoding="utf-8"
            )
            gate = subprocess.run(
                [sys.executable, str(skill / "scripts/verify_gates.py"),
                 "--before", str(run_dir / "01_input.txt"),
                 "--after", str(run_dir / "final.md"),
                 "--genre", "essay", "--json"],
                capture_output=True,
                text=True,
                encoding="utf-8",
                check=False,
            )
            self.assertEqual(gate.returncode, 0, gate.stdout + gate.stderr)


if __name__ == "__main__":
    unittest.main()
