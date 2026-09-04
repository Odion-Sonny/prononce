#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${ROOT_DIR}"

echo "==> Generating iconset PNGs..."
swift scripts/generate_icon.swift

echo "==> Converting iconset to AppIcon.icns..."
iconutil -c icns Resources/AppIcon.iconset -o Resources/AppIcon.icns
rm -rf Resources/AppIcon.iconset

echo "==> AppIcon.icns generated at Resources/AppIcon.icns"
