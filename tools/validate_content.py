#!/usr/bin/env python3
"""Valide le contenu de CyberPath CI : schéma JSON et cohérence entre fichiers.

Usage : python3 tools/validate_content.py
Code de sortie 1 si une erreur est trouvée.
"""
import json
import sys
from pathlib import Path

try:
    import jsonschema
except ImportError:
    sys.exit("Installe jsonschema : pip install jsonschema")

ROOT = Path(__file__).resolve().parent.parent
CONTENT = ROOT / "content"
LEVELS = {"BTS1", "BTS2", "L1", "L2", "L3", "AUTO"}
SPECIALTIES = {"defensive", "offensive", "forensic", "grc"}


def load(name):
    with open(CONTENT / name, encoding="utf-8") as f:
        return json.load(f)


def check_roadmap(roadmap, errors):
    track_ids = set()
    for track in roadmap["tracks"]:
        tid = track["id"]
        if tid in track_ids:
            errors.append(f"piste en double : {tid}")
        track_ids.add(tid)
        steps = track["steps"]
        ids = [s["id"] for s in steps]
        if len(ids) != len(set(ids)):
            errors.append(f"{tid} : identifiants d'étape en double")
        position = {sid: i for i, sid in enumerate(ids)}

        for step in steps:
            sid = step["id"]
            if step["code"].lower() != sid:
                errors.append(f"{sid} : le code {step['code']} ne correspond pas à l'id")
            for req in step["requires"]:
                if req not in position:
                    errors.append(f"{sid} : prérequis inconnu {req}")
                elif position[req] >= position[sid]:
                    errors.append(f"{sid} : le prérequis {req} doit venir avant")
            for unlock in step.get("unlocks", []):
                if unlock not in SPECIALTIES:
                    errors.append(f"{sid} : spécialité inconnue {unlock}")

        entry_points = track.get("entry_points", {})
        for level, sid in entry_points.items():
            if level not in LEVELS:
                errors.append(f"{tid} : niveau inconnu {level}")
            if sid not in position:
                errors.append(f"{tid} : point d'entrée inconnu {sid} pour {level}")
        if tid == "tronc-commun":
            missing = LEVELS - set(entry_points)
            if missing:
                errors.append(f"tronc-commun : niveaux sans point d'entrée {sorted(missing)}")
    if "tronc-commun" not in track_ids:
        errors.append("la piste tronc-commun est obligatoire")


def check_certifications(certs, step_ids, errors):
    for cert in certs["certifications"]:
        after = cert.get("after_step")
        if after and after not in step_ids:
            errors.append(f"certification {cert['id']} : étape inconnue {after}")
        if cert.get("price_usd") is not None and cert["price_usd"] <= 0:
            errors.append(f"certification {cert['id']} : prix invalide")
    return {c["id"] for c in certs["certifications"]}


def check_careers(careers, cert_ids, errors):
    ids = {s["id"] for s in careers["specialties"]}
    if ids != SPECIALTIES:
        errors.append(f"careers.json : spécialités attendues {sorted(SPECIALTIES)}")
    for spec in careers["specialties"]:
        cert = spec.get("certification")
        if cert and cert not in cert_ids:
            errors.append(f"careers.json : certification inconnue {cert}")


def main():
    errors = []
    roadmap = load("roadmap.json")
    schema = load("schema.json")
    try:
        jsonschema.validate(roadmap, schema)
    except jsonschema.ValidationError as e:
        path = "/".join(str(p) for p in e.absolute_path)
        print(f"Schéma invalide à {path or 'la racine'} : {e.message}")
        return 1

    check_roadmap(roadmap, errors)
    step_ids = {s["id"] for t in roadmap["tracks"] for s in t["steps"]}
    cert_ids = check_certifications(load("certifications.json"), step_ids, errors)
    check_careers(load("careers.json"), cert_ids, errors)

    if errors:
        print("Contenu invalide :")
        for e in errors:
            print(f"  - {e}")
        return 1

    steps = sum(len(t["steps"]) for t in roadmap["tracks"])
    print(f"Contenu valide : version {roadmap['version']}, {len(roadmap['tracks'])} piste(s), {steps} étapes.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
