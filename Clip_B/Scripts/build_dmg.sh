#!/bin/bash
#
#  build_dmg.sh
#  ClipB — Build release app bundle and package into a DMG installer
#
#  Usage:  ./Scripts/build_dmg.sh
#  Output: dist/ClipB-1.0.0.dmg
#

set -e

# ─── Configuration ───────────────────────────────────────────────
APP_NAME="ClipB"
VERSION="1.0.0"
BUNDLE_ID="com.clipb.app"

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/dist"
STAGING_DIR="${BUILD_DIR}/staging"
APP_DIR="${STAGING_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
DMG_NAME="${APP_NAME}-${VERSION}"
DMG_PATH="${BUILD_DIR}/${DMG_NAME}.dmg"
DMG_TEMP="${BUILD_DIR}/${DMG_NAME}-temp.dmg"

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║        ClipB DMG Installer Builder v${VERSION}        ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ─── Clean ───────────────────────────────────────────────────────
echo "🧹 Cleaning previous builds..."
rm -rf "${BUILD_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# ─── Compile (Release) ──────────────────────────────────────────
echo "🔨 Compiling ${APP_NAME} in release mode..."
cd "${PROJECT_ROOT}"
swift build -c release 2>&1

ARCH=$(uname -m)
BINARY_PATH="${PROJECT_ROOT}/.build/${ARCH}-apple-macosx/release/${APP_NAME}"
BUNDLE_RESOURCE="${PROJECT_ROOT}/.build/${ARCH}-apple-macosx/release/${APP_NAME}_${APP_NAME}.bundle"

if [ ! -f "${BINARY_PATH}" ]; then
    echo "❌ Error: Binary not found at ${BINARY_PATH}"
    exit 1
fi

echo "✅ Compilation successful!"

# ─── Assemble App Bundle ────────────────────────────────────────
echo "📦 Assembling ${APP_NAME}.app bundle..."

# Copy binary
cp "${BINARY_PATH}" "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

# Copy resource bundle
if [ -d "${BUNDLE_RESOURCE}" ]; then
    cp -R "${BUNDLE_RESOURCE}" "${RESOURCES_DIR}/"
fi

# Copy Info.plist
cp "${PROJECT_ROOT}/ClipB/Info.plist" "${CONTENTS_DIR}/Info.plist"

# Copy entitlements (for reference)
if [ -f "${PROJECT_ROOT}/ClipB/ClipB.entitlements" ]; then
    cp "${PROJECT_ROOT}/ClipB/ClipB.entitlements" "${CONTENTS_DIR}/ClipB.entitlements"
fi

# Create PkgInfo
echo -n "APPL????" > "${CONTENTS_DIR}/PkgInfo"

# Copy App Icon
if [ -f "${PROJECT_ROOT}/ClipB/Resources/AppIcon.icns" ]; then
    cp "${PROJECT_ROOT}/ClipB/Resources/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
fi

echo "✅ App bundle assembled!"

# Ad-hoc sign the app bundle (required for Apple Silicon)
echo "🔐 Signing app bundle..."
codesign --force --deep --sign - "${CONTENTS_DIR}/.."
echo "✅ App bundle signed!"

# ─── Verify App Bundle ──────────────────────────────────────────
echo "🔍 Verifying app bundle structure..."
if [ ! -f "${MACOS_DIR}/${APP_NAME}" ]; then
    echo "❌ Error: Binary missing from app bundle"
    exit 1
fi
if [ ! -f "${CONTENTS_DIR}/Info.plist" ]; then
    echo "❌ Error: Info.plist missing from app bundle"
    exit 1
fi
echo "   ✓ Binary:     ${MACOS_DIR}/${APP_NAME}"
echo "   ✓ Info.plist: ${CONTENTS_DIR}/Info.plist"
echo "   ✓ PkgInfo:    ${CONTENTS_DIR}/PkgInfo"

# ─── Create DMG ─────────────────────────────────────────────────
echo "💿 Creating DMG installer..."

# Create a temporary directory for DMG contents
DMG_CONTENT="${BUILD_DIR}/dmg_content"
rm -rf "${DMG_CONTENT}"
mkdir -p "${DMG_CONTENT}"

# Copy app into DMG content
cp -R "${APP_DIR}" "${DMG_CONTENT}/"

# Create Applications symlink (drag-to-install)
ln -s /Applications "${DMG_CONTENT}/Applications"

# Set DMG Volume Icon
if [ -f "${PROJECT_ROOT}/ClipB/Resources/AppIcon.icns" ]; then
    cp "${PROJECT_ROOT}/ClipB/Resources/AppIcon.icns" "${DMG_CONTENT}/.VolumeIcon.icns"
    SetFile -c icnC "${DMG_CONTENT}/.VolumeIcon.icns"
    SetFile -a C "${DMG_CONTENT}"
fi

# Create a README file inside DMG
cat > "${DMG_CONTENT}/README.txt" << 'EOF'
╔═══════════════════════════════════════════════════╗
║              ClipB — Installation                  ║
╠═══════════════════════════════════════════════════╣
║                                                    ║
║  Drag ClipB.app into the Applications folder       ║
║  to install.                                       ║
║                                                    ║
║  After installing, launch ClipB from:              ║
║  • Spotlight (⌘Space → type "ClipB")              ║
║  • Applications folder                             ║
║  • Launchpad                                       ║
║                                                    ║
║  ClipB runs as a menu bar app. Look for the        ║
║  clipboard icon (📋) in the top-right of your      ║
║  screen.                                           ║
║                                                    ║
║  Keyboard Shortcuts:                               ║
║  ⌘⇧V      Open ClipB Window                      ║
║  ⌘⇧Space  Quick Search                           ║
║  ⌘⌥V      Quick Paste                            ║
║  ⌘⇧,      Open Settings                          ║
║  ⌘⇧A      Open AI Assistant                      ║
║                                                    ║
╚═══════════════════════════════════════════════════╝
EOF

# Calculate size
APP_SIZE_KB=$(du -sk "${DMG_CONTENT}" | cut -f1)
echo "   App size: ${APP_SIZE_KB} KB"

# Create compressed read-only DMG directly (no temp mount needed)
rm -f "${DMG_PATH}"
hdiutil create \
    -srcfolder "${DMG_CONTENT}" \
    -volname "${APP_NAME}" \
    -fs HFS+ \
    -format UDZO \
    -imagekey zlib-level=9 \
    "${DMG_PATH}" \
    2>&1

# Clean up staging
rm -rf "${DMG_CONTENT}"

# ─── Done ────────────────────────────────────────────────────────
DMG_SIZE=$(ls -lh "${DMG_PATH}" | awk '{print $5}')

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║              Build Complete! 🎉                  ║"
echo "╠══════════════════════════════════════════════════╣"
echo "║                                                  ║"
echo "  📀 DMG:  ${DMG_PATH}"
echo "  📦 App:  ${APP_DIR}"
echo "  📏 Size: ${DMG_SIZE}"
echo "║                                                  ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "To install: Double-click the DMG, then drag ClipB"
echo "            into the Applications folder."
echo ""

