#!/usr/bin/env python3
"""Copie content/*.json vers app/assets/content/, où l'app les embarque.

Usage :
  python3 tools/sync_content.py          copie les fichiers
  python3 tools/sync_content.py --check  échoue si la copie n'est pas à jour (CI)
"""
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "content"
TARGET = ROOT / "app" / "assets" / "content"
FILES = [
    "roadmap.json",
    "certifications.json",
    "careers.json",
    "methodology.json",
    "tools.json",
    "services.json",
]


def main():
    check = "--check" in sys.argv
    stale = []
    TARGET.mkdir(parents=True, exist_ok=True)
    for name in FILES:
        src, dst = SOURCE / name, TARGET / name
        if dst.exists() and dst.read_bytes() == src.read_bytes():
            continue
        if check:
            stale.append(name)
        else:
            shutil.copyfile(src, dst)
            print(f"copié : {name}")
    if stale:
        print("app/assets/content n'est pas à jour : " + ", ".join(stale))
        print("Lance : python3 tools/sync_content.py")
        return 1
    if check:
        print("app/assets/content est à jour.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
