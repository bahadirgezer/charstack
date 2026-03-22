#!/usr/bin/env python3
import json
import os
from pathlib import Path

checklist_path = Path("appstore-assets/review/submission-checklist.json")
if not checklist_path.exists():
    raise SystemExit("error: missing appstore-assets/review/submission-checklist.json")

payload = json.loads(checklist_path.read_text(encoding="utf-8"))

required_string_fields = [
    "privacyPolicyUrl",
    "supportUrl",
    "description",
    "subtitle",
    "keywords",
    "reviewNotesPath",
]

missing = [field for field in required_string_fields if not str(payload.get(field, "")).strip()]
if missing:
    raise SystemExit(f"error: missing checklist fields: {', '.join(missing)}")

for bool_field in ["ageRatingConfirmed", "exportComplianceConfirmed"]:
    if payload.get(bool_field) is not True:
        raise SystemExit(f"error: checklist requires {bool_field}=true")

notes_path = Path(payload["reviewNotesPath"])
if not notes_path.exists():
    raise SystemExit(f"error: review notes file not found: {notes_path}")

support_url = os.environ.get("ASC_SUPPORT_URL", "").strip()
if support_url and payload["supportUrl"] != support_url:
    raise SystemExit("error: checklist supportUrl does not match vars.ASC_SUPPORT_URL")

privacy_policy_url = os.environ.get("ASC_PRIVACY_POLICY_URL", "").strip()
if privacy_policy_url and payload["privacyPolicyUrl"] != privacy_policy_url:
    raise SystemExit("error: checklist privacyPolicyUrl does not match vars.ASC_PRIVACY_POLICY_URL")

version = os.environ.get("VERSION", "").strip()
if not version:
    raise SystemExit("error: VERSION env var is required")

Path("build").mkdir(parents=True, exist_ok=True)
artifact = {"version": version, "checklist": payload}
Path("build/submission-preflight.json").write_text(json.dumps(artifact, indent=2), encoding="utf-8")
