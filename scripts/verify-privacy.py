"""Check the app's required-reason manifest and its built-bundle inclusion."""
from pathlib import Path
import plistlib
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
if len(sys.argv) > 1:
    bundled = Path(sys.argv[1]) / "PrivacyInfo.xcprivacy"
    with bundled.open("rb") as stream:
        if plistlib.load(stream) != manifest:
            raise SystemExit("Built app privacy manifest differs from source.")
    print("PASS: required-reason privacy manifest included in built app")
else:
    print("PASS: app preferences and elapsed-time privacy declarations")
