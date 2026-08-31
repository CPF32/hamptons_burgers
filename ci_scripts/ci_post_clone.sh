#!/bin/sh
# Xcode Cloud runs this after cloning. Gitignored secrets are not in the repo,
# so we materialize them from .example templates (and optional workflow env vars).
set -euo pipefail

cd "${CI_PRIMARY_REPOSITORY_PATH}"

echo "→ Preparing gitignored config for CI"

BRAND_CONFIG="HamptonsBurgers/Config/BrandConfig.swift"
if [ ! -f "$BRAND_CONFIG" ]; then
  cp "HamptonsBurgers/Config/BrandConfig.swift.example" "$BRAND_CONFIG"
  echo "  Created $BRAND_CONFIG from example"
fi

if [ -n "${FIRESTORE_ADMIN_WRITE_SECRET:-}" ]; then
  /usr/bin/sed -i '' "s/REPLACE-WITH-YOUR-ADMIN-WRITE-SECRET/${FIRESTORE_ADMIN_WRITE_SECRET}/g" "$BRAND_CONFIG"
  echo "  Injected FIRESTORE_ADMIN_WRITE_SECRET"
fi

setup_firebase_plist() {
  env_name="$1"
  var_name="$2"
  dest="Firebase/GoogleService-Info-${env_name}.plist"
  example="Firebase/GoogleService-Info-${env_name}.plist.example"

  if [ -f "$dest" ]; then
    echo "  $dest already present"
    return
  fi

  # shellcheck disable=SC1083
  encoded=$(eval "echo \"\${${var_name}:-}\"")
  if [ -n "$encoded" ]; then
    echo "$encoded" | base64 -D > "$dest"
    echo "  Created $dest from ${var_name}"
  elif [ -f "$example" ]; then
    cp "$example" "$dest"
    echo "  Created $dest from example"
  else
    echo "warning: missing $example"
  fi
}

setup_firebase_plist "Dev" "GOOGLE_SERVICE_INFO_DEV"
setup_firebase_plist "Prod" "GOOGLE_SERVICE_INFO_PROD"

echo "→ CI config ready"
