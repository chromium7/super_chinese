"""Keep networking APIs and package dependencies out of the offline app target."""

from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parent.parent
violations = []
for source in sorted((root / "HanziLevels").rglob("*.swift")):
    for number, line in enumerate(source.read_text(encoding="utf-8").splitlines(), 1):
        if re.search(r"\b(URLSession|URLRequest|WKWebView)\b|^\s*import\s+(Network|WebKit|CloudKit)\b", line):
            violations.append(f"{source.relative_to(root)}:{number}: {line.strip()}")

project = (root / "HanziLevels.xcodeproj/project.pbxproj").read_text(encoding="utf-8")
if "XCRemoteSwiftPackageReference" in project or "XCSwiftPackageProductDependency" in project:
    violations.append("The app project must not depend on third-party packages.")

if violations:
    sys.exit("Offline check failed:\n" + "\n".join(violations))

print("Offline source check passed: no networking APIs or Swift package dependencies.")
