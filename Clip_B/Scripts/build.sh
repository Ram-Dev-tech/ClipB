#!/bin/bash
#
#  build.sh
#  ClipB
#
#  Created by ClipB Team on 2026-07-18.
#  Copyright © 2026 ClipB. All rights reserved.
#

set -e

# Define directories
PROJECT_ROOT="$(pwd)"
BUILD_DIR="${PROJECT_ROOT}/build"
APP_DIR="${BUILD_DIR}/ClipB.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MAC_OS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "[ClipB] Creating build directory structure..."
mkdir -p "${MAC_OS_DIR}"
mkdir -p "${RESOURCES_DIR}"

echo "[ClipB] Compiling target with Swift Package Manager..."
swift build -c debug

# Locate compiled files
TARGET_DIR="${PROJECT_ROOT}/.build/arm64-apple-macosx/debug"
BINARY_PATH="${TARGET_DIR}/ClipB"
BUNDLE_PATH="${TARGET_DIR}/ClipB_ClipB.bundle"

echo "[ClipB] Copying compiled binary to app bundle..."
cp "${BINARY_PATH}" "${MAC_OS_DIR}/ClipB"

echo "[ClipB] Copying resources to app bundle..."
if [ -d "${BUNDLE_PATH}" ]; then
    cp -R "${BUNDLE_PATH}" "${RESOURCES_DIR}/"
fi

echo "[ClipB] Copying Info.plist..."
cp "${PROJECT_ROOT}/ClipB/Info.plist" "${CONTENTS_DIR}/Info.plist"

# Verify structure
echo "[ClipB] Verifying app bundle..."
if [ -f "${MAC_OS_DIR}/ClipB" ] && [ -f "${CONTENTS_DIR}/Info.plist" ]; then
    echo "[ClipB] Successfully packaged ClipB.app!"
    echo "[ClipB] Location: ${APP_DIR}"
else
    echo "[ClipB] Error: Packaging verification failed."
    exit 1
fi
