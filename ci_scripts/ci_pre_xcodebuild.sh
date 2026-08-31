#!/bin/sh
# Runs immediately before xcodebuild in Xcode Cloud.
set -euo pipefail

cd "${CI_PRIMARY_REPOSITORY_PATH}"

"${CI_PRIMARY_REPOSITORY_PATH}/ci_scripts/ci_post_clone.sh"
