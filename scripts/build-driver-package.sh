#!/bin/bash

set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
output_path="${1:-$project_root/dist/ON AIR Deck Audio Driver.pkg}"
derived_data_path="${DERIVED_DATA_PATH:-$project_root/build/AudioDriverPackage}"
temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/on-air-deck-driver-package.XXXXXX")"

cleanup() {
  rm -rf "$temporary_root"
}
trap cleanup EXIT

cd "$project_root"

xcodebuild \
  -project AudioDriver/ONAirAudio.xcodeproj \
  -scheme NullAudio \
  -configuration Release \
  -derivedDataPath "$derived_data_path" \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  build

built_driver="$derived_data_path/Build/Products/Release/OnAirDeckAudio.driver"
payload_driver="$temporary_root/payload/Library/Audio/Plug-Ins/HAL/OnAirDeckAudio.driver"
temporary_package="$temporary_root/ON AIR Deck Audio Driver.pkg"

mkdir -p "$(dirname "$payload_driver")" "$(dirname "$output_path")"
ditto "$built_driver" "$payload_driver"
codesign --force --deep --sign - "$payload_driver"

driver_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$payload_driver/Contents/Info.plist")"
driver_architectures="$(lipo -archs "$payload_driver/Contents/MacOS/OnAirDeckAudio")"
driver_minimum_os="$(otool -l "$payload_driver/Contents/MacOS/OnAirDeckAudio" | awk '/LC_BUILD_VERSION/{found=1; next} found && /minos/{print $2; exit}')"

if [[ " $driver_architectures " != *" arm64 "* || " $driver_architectures " != *" x86_64 "* ]]; then
  echo "Driver must contain arm64 and x86_64 slices: $driver_architectures" >&2
  exit 1
fi

if [[ "$driver_minimum_os" != "14.0" ]]; then
  echo "Driver minimum OS must be 14.0, got $driver_minimum_os" >&2
  exit 1
fi

cmp "$project_root/LICENSE" "$payload_driver/Contents/Resources/LICENSE"
cmp "$project_root/AudioDriver/LICENSE.txt" "$payload_driver/Contents/Resources/LICENSE.txt"
codesign --verify --deep --strict "$payload_driver"

pkgbuild \
  --root "$temporary_root/payload" \
  --identifier jp.ryonihonyanagi.OnAirDeckAudio \
  --version "$driver_version" \
  --install-location / \
  --scripts "$project_root/Packaging/scripts" \
  "$temporary_package"

mv -f "$temporary_package" "$output_path"

pkgutil --payload-files "$output_path" \
  | grep -Fqx './Library/Audio/Plug-Ins/HAL/OnAirDeckAudio.driver/Contents/MacOS/OnAirDeckAudio'

echo "Built unsigned driver package: $output_path"
echo "Driver version: $driver_version"
echo "Driver architectures: $driver_architectures"
echo "Driver minimum OS: $driver_minimum_os"
echo "SHA-256: $(shasum -a 256 "$output_path" | awk '{print $1}')"
