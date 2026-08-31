#!/bin/bash
set -euo pipefail

# Copies the correct GoogleService-Info plist into the app bundle based on FIREBASE_ENV.
# Debug builds → Dev, Release/Archive builds → Prod (set via Xcode build settings).

ENV_NAME="${FIREBASE_ENV:-Dev}"
SRC="${SRCROOT}/Firebase/GoogleService-Info-${ENV_NAME}.plist"
DEST_DIR="${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
DEST="${DEST_DIR}/GoogleService-Info.plist"

mkdir -p "${DEST_DIR}"

if [[ ! -f "${SRC}" ]]; then
  echo "warning: Missing Firebase config at ${SRC}"
  echo "warning: Copy Firebase/GoogleService-Info-${ENV_NAME}.plist.example → Firebase/GoogleService-Info-${ENV_NAME}.plist"
  echo "warning: App will run without Firebase until that file is added."
  # Remove stale plist so the app does not silently use the wrong environment.
  rm -f "${DEST}"
  exit 0
fi

cp "${SRC}" "${DEST}"
echo "Firebase: using ${ENV_NAME} → ${DEST}"
