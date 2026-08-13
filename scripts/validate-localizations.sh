#!/bin/bash

set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
resources_root="$project_root/OnAirDeck/Resources"
locales=(en ja zh-Hans ko)
reference_locale="en"

extract_keys() {
  sed -n 's/^"\(.*\)"[[:space:]]*=.*/\1/p' "$1" | LC_ALL=C sort
}

temporary_root="$(mktemp -d)"
trap 'rm -rf "$temporary_root"' EXIT

reference_file="$resources_root/$reference_locale.lproj/Localizable.strings"
extract_keys "$reference_file" > "$temporary_root/reference.keys"

for locale in "${locales[@]}"; do
  strings_file="$resources_root/$locale.lproj/Localizable.strings"
  info_file="$resources_root/$locale.lproj/InfoPlist.strings"

  plutil -lint "$strings_file" >/dev/null
  plutil -lint "$info_file" >/dev/null
  extract_keys "$strings_file" > "$temporary_root/$locale.keys"

  if ! diff -u "$temporary_root/reference.keys" "$temporary_root/$locale.keys"; then
    echo "Localization keys differ for $locale" >&2
    exit 1
  fi
done

key_count="$(wc -l < "$temporary_root/reference.keys" | tr -d ' ')"
echo "Localization validation passed: ${#locales[@]} locales, $key_count keys each."
