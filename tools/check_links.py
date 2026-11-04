#!/usr/bin/env python3
"""Vérifie que les liens de content/ répondent.

Échoue sur les liens introuvables (404, 410, erreur réseau persistante).
Les réponses 401, 403 et 429 sont signalées sans faire échouer : beaucoup de
plateformes bloquent les robots alors que la page existe.
"""
import json
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONTENT = ROOT / "content"
SOFT = {401, 403, 429}
HEADERS = {"User-Agent": "CyberPathCI-LinkCheck/1.0 (+https://github.com)"}


def collect_urls():
    urls = {}
    roadmap = json.loads((CONTENT / "roadmap.json").read_text(encoding="utf-8"))
    for track in roadmap["tracks"]:
        for step in track["steps"]:
            for link in step["resources"] + step["labs"]:
                urls.setdefault(link["url"], step["id"])
    certs = json.loads((CONTENT / "certifications.json").read_text(encoding="utf-8"))
    for cert in certs["certifications"]:
        urls.setdefault(cert["url"], cert["id"])
    tools = json.loads((CONTENT / "tools.json").read_text(encoding="utf-8"))
    for tool in tools["tools"]:
        for src in tool["sources"]:
            urls.setdefault(src["url"], tool["id"])
    services = json.loads((CONTENT / "services.json").read_text(encoding="utf-8"))
    for service in services["services"]:
        for lab in service["legal_labs"]:
            urls.setdefault(lab["url"], service["id"])
    return urls


def fetch(url):
    last = "aucune réponse"
    for method in ("HEAD", "GET"):
        req = urllib.request.Request(url, method=method, headers=HEADERS)
        try:
            with urllib.request.urlopen(req, timeout=20) as resp:
                return resp.status
        except urllib.error.HTTPError as e:
            if method == "HEAD" and e.code in (403, 405, 501):
                continue
            return e.code
        except Exception as e:  # noqa: BLE001 - on veut tout rapporter
            last = str(e)
    return last


def main():
    urls = collect_urls()
    broken, soft = [], []
    for url, where in sorted(urls.items()):
        result = None
        for attempt in range(2):
            result = fetch(url)
            if isinstance(result, int) and result < 400:
                break
            time.sleep(2)
        if isinstance(result, int) and result < 400:
            print(f"ok   {url}")
        elif result in SOFT:
            soft.append((url, where, result))
            print(f"~    {url} ({result})")
        else:
            broken.append((url, where, result))
            print(f"KO   {url} ({result})")

    print(f"\n{len(urls)} liens, {len(broken)} cassés, {len(soft)} à vérifier à la main.")
    for url, where, result in broken:
        print(f"  cassé : {url} ({where}) -> {result}")
    return 1 if broken else 0


if __name__ == "__main__":
    sys.exit(main())
