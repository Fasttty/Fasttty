#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
xcodegen generate
xcodebuild -project Ryadom.xcodeproj -target Ryadom -configuration Release -sdk iphoneos \
  CONFIGURATION_BUILD_DIR="$PWD/out/device" CODE_SIGNING_ALLOWED=NO build
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir "$work/Payload"
ditto out/device/Ryadom.app "$work/Payload/Ryadom.app"
mkdir -p out
rm -f out/Ryadom-unsigned.ipa
(cd "$work"; zip -qry "$OLDPWD/out/Ryadom-unsigned.ipa" Payload)
unzip -l out/Ryadom-unsigned.ipa | grep 'Payload/Ryadom.app/Info.plist'
