#!/bin/bash
# Double-click to generate the Xcode project and open it.
# Installs XcodeGen via Homebrew if it's missing.

set -e
cd "$(dirname "$0")"
echo "== ToneVault build setup =="

if ! command -v xcodegen >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    echo "Installing XcodeGen via Homebrew (one-time)…"
    brew install xcodegen
  else
    echo "Homebrew isn't installed. Install it from https://brew.sh then re-run this,"
    echo "or install XcodeGen another way. Stopping."
    echo "Press any key to close."; read -n 1 -s; exit 1
  fi
fi

echo "Generating ToneVault.xcodeproj…"
xcodegen generate

echo "Opening in Xcode…"
open ToneVault.xcodeproj

echo
echo "Done. Xcode is opening the project."
echo "Next in Xcode: select the ToneVault target → Signing & Capabilities →"
echo "  check 'Automatically manage signing' and pick your Team."
echo
echo "Press any key to close."
read -n 1 -s
