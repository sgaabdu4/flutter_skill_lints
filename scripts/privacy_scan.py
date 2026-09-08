#!/usr/bin/env python3
"""Run the canonical Hard Eng privacy scanner."""

from __future__ import annotations

import os
import runpy
import sys
from pathlib import Path


def main() -> None:
    runtime = os.environ.get("HARD_ENG_RUNTIME")
    roots = [Path(runtime)] if runtime else []
    roots.append(Path.home() / ".agents")
    for root in roots:
        scanner = root / "skills/deterministic-checks/scripts/privacy_scan.py"
        if scanner.is_file():
            sys.argv[0] = str(scanner)
            runpy.run_path(str(scanner), run_name="__main__")
            return
    raise SystemExit("The canonical Hard Eng privacy scanner is unavailable.")


if __name__ == "__main__":
    main()
