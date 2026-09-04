#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${ROOT_DIR}"

APP_NAME="Prononce"
BUILD_DIR="${ROOT_DIR}/build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
DMG_PATH="${BUILD_DIR}/${APP_NAME}.dmg"
STAGE_DIR="${BUILD_DIR}/dmg_stage"

# Ensure .app bundle is built
if [[ ! -d "${APP_BUNDLE}" ]]; then
    echo "==> ${APP_BUNDLE} not found. Building now..."
    "${SCRIPT_DIR}/build_app.sh"
fi

echo "=========================================="
echo " Creating Distributable DMG: ${APP_NAME} "
echo "=========================================="

# Clean previous DMG and staging area
rm -rf "${STAGE_DIR}" "${DMG_PATH}"
mkdir -p "${STAGE_DIR}"

# Copy .app bundle into staging
echo "==> Copying ${APP_NAME}.app to DMG staging..."
cp -R "${APP_BUNDLE}" "${STAGE_DIR}/"

# Create /Applications symlink for drag-and-drop installation
echo "==> Creating Applications symlink..."
ln -s /Applications "${STAGE_DIR}/Applications"

# Build DMG using hdiutil
echo "==> Creating disk image (${DMG_PATH})..."
hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "${STAGE_DIR}" \
    -ov \
    -format UDZO \
    "${DMG_PATH}"

# Clean up staging directory
rm -rf "${STAGE_DIR}"

echo "=========================================="
echo " Distributable DMG Created: ${DMG_PATH}"
echo " Size: $(du -sh "${DMG_PATH}" | cut -f1)"
echo "=========================================="
