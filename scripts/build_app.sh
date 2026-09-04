#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${ROOT_DIR}"

APP_NAME="Prononce"
BUILD_DIR="${ROOT_DIR}/build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"

echo "=========================================="
echo " Building ${APP_NAME} for macOS (Release) "
echo "=========================================="

# 1. Build release binary using Swift Package Manager
echo "==> Compiling Release binary..."
swift build -c release

BIN_PATH="$(swift build -c release --show-bin-path)/${APP_NAME}"

if [[ ! -f "${BIN_PATH}" ]]; then
    echo "Error: Binary not found at ${BIN_PATH}" >&2
    exit 1
fi

# 2. Ensure AppIcon.icns exists
if [[ ! -f "Resources/AppIcon.icns" ]]; then
    echo "==> Generating AppIcon.icns..."
    "${SCRIPT_DIR}/generate_icon.sh"
fi

# 3. Clean and construct .app bundle directory hierarchy
echo "==> Assembling ${APP_NAME}.app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# 4. Copy executable, Info.plist, and Icon
cp "${BIN_PATH}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

cp "Resources/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"
cp "Resources/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"

# 5. Ad-hoc codesign the bundle
echo "==> Codesigning ${APP_NAME}.app..."
codesign --force --deep --sign - "${APP_BUNDLE}"

# 6. Verify signature
echo "==> Verifying signature..."
codesign --verify --verbose "${APP_BUNDLE}"

echo "=========================================="
echo " Successfully built: ${APP_BUNDLE}"
echo " Size: $(du -sh "${APP_BUNDLE}" | cut -f1)"
echo "=========================================="
