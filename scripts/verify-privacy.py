"""Check the app's required-reason manifest and its built-bundle inclusion."""
from pathlib import Path
import plistlib
import json
import subprocess
import sys

source = Path(__file__).resolve().parents[1] / "MARC/PrivacyInfo.xcprivacy"
with source.open("rb") as stream:
    manifest = plistlib.load(stream)
expected = {
    "NSPrivacyAccessedAPICategoryUserDefaults": ["CA92.1"],
    "NSPrivacyAccessedAPICategorySystemBootTime": ["35F9.1"],
    "NSPrivacyAccessedAPICategoryDiskSpace": ["E174.1"],
}
actual = {entry["NSPrivacyAccessedAPIType"]: entry["NSPrivacyAccessedAPITypeReasons"]
          for entry in manifest["NSPrivacyAccessedAPITypes"]}
if actual != expected or manifest.get("NSPrivacyTracking") is not False:
    raise SystemExit("Privacy manifest declarations differ from the reviewed app usage.")
from urllib.parse import urlparse

policies = []
for resource, slug in [("MARCPrivacyPolicy", "privacy"), ("MARCTermsOfUse", "terms")]:
    policy = source.parent / ("Resources/" + resource + ".json")
    document = json.loads(policy.read_text())
    required = ["title", "effectiveDate", "introduction", "contactEmail", "publishedURL"]
    if not all(isinstance(document.get(key), str) and document[key].strip() for key in required):
        raise SystemExit("Legal document metadata is missing: " + resource)
    if document["publishedURL"] != "https://getmarc.app/" + slug:
        raise SystemExit("Unexpected published legal URL: " + resource)
    sections = document.get("sections", [])
    if not sections or len({section["id"] for section in sections}) != len(sections):
        raise SystemExit("Legal sections are missing or duplicated: " + resource)
    for section in sections:
        if not section["id"] or not section["title"] or not section["paragraphs"]:
            raise SystemExit("Empty legal section: " + resource)
        if not all(isinstance(text, str) and text.strip() for text in section["paragraphs"]):
            raise SystemExit("Invalid legal paragraph: " + resource)
        for link in section["links"]:
            url = urlparse(link["url"])
            if url.scheme not in ("https", "mailto") or not link["title"]:
                raise SystemExit("Unsafe legal reference: " + resource)
            if url.scheme == "https" and (not url.hostname or url.username or url.password):
                raise SystemExit("Invalid legal reference: " + resource)
    policies.append(policy)
settings = (source.parents[1] / "MARC/Screens/SettingsScreen.swift").read_text()
for page in ("privacy", "terms"):
    if "MARCLegalScreen(." + page + ")" not in settings:
        raise SystemExit("Missing offline legal screen in Settings: " + page)
if "marc.thechougala.in" in settings:
    raise SystemExit("Settings still points at the retired MARC website.")
subprocess.run([sys.executable, str(source.parents[1] / "scripts/render-privacy.py"), "--check"], check=True)
if len(sys.argv) > 1:
    bundled = Path(sys.argv[1]) / "PrivacyInfo.xcprivacy"
    with bundled.open("rb") as stream:
        if plistlib.load(stream) != manifest:
            raise SystemExit("Built app privacy manifest differs from source.")
    print("PASS: required-reason privacy manifest included in built app")
    for policy in policies:
        candidates = [Path(sys.argv[1]) / policy.name,
                      Path(sys.argv[1]) / "Resources" / policy.name]
        if not any(path.is_file() and path.read_bytes() == policy.read_bytes() for path in candidates):
            raise SystemExit("Built app is missing the current offline document: " + policy.name)
        print("PASS: current offline legal document included in built app: " + policy.name)

else:
    print("PASS: privacy declarations, legal document validation and offline Settings routes")
