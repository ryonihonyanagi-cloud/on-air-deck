#!/bin/bash

set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
derived_data_path="${DERIVED_DATA_PATH:-$project_root/build/DerivedDataCI}"

cd "$project_root"
./scripts/validate-localizations.sh
xcodegen generate
xcodebuild \
  -project OnAirDeck.xcodeproj \
  -scheme OnAirDeck \
  -configuration Debug \
  -derivedDataPath "$derived_data_path" \
  CODE_SIGNING_ALLOWED=NO \
  test
