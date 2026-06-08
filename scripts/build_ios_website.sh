#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/website/downloads/ios/skrol.ipa"

mkdir -p "$ROOT/website/downloads/ios"

cd "$ROOT"

echo "Building iOS IPA..."
flutter build ipa --release

IPA_SRC=$(find "$ROOT/build/ios/ipa" -name "*.ipa" | head -1)
if [[ -z "$IPA_SRC" ]]; then
  echo "IPA not found under build/ios/ipa"
  exit 1
fi

cp "$IPA_SRC" "$OUT"
echo "Copied to $OUT ($(du -h "$OUT" | cut -f1))"
