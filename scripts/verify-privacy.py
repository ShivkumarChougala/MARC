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
}
actual = {entry["NSPrivacyAccessedAPIType"]: entry["NSPrivacyAccessedAPITypeReasons"]
          for entry in manifest["NSPrivacyAccessedAPITypes"]}
if actual != expected or manifest.get("NSPrivacyTracking") is not False:
    raise SystemExit("Privacy manifest declarations differ from the reviewed app usage.")
policy = source.parent / "Resources/MARCPrivacyPolicy.json"
document = json.loads(policy.read_text())
if not document.get("sections") or len({section["id"] for section in document["sections"]}) != len(document["sections"]):
    raise SystemExit("Privacy policy sections are missing or duplicated.")
subprocess.run([sys.executable, str(source.parents[1] / "scripts/render-privacy.py"), "--check"], check=True)
if len(sys.argv) > 1:
    bundled = Path(sys.argv[1]) / "PrivacyInfo.xcprivacy"
    with bundled.open("rb") as stream:
        if plistlib.load(stream) != manifest:
            raise SystemExit("Built app privacy manifest differs from source.")
    print("PASS: required-reason privacy manifest included in built app")
    candidates = [Path(sys.argv[1]) / "MARCPrivacyPolicy.json",
                  Path(sys.argv[1]) / "Resources/MARCPrivacyPolicy.json"]
    if not any(path.is_file() and path.read_bytes() == policy.read_bytes() for path in candidates):
        raise SystemExit("Built app is missing the current offline privacy policy.")
    print("PASS: current offline privacy policy included in built app")
else:
    print("PASS: app preferences and elapsed-time privacy declarations")
