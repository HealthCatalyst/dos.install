#!/bin/bash
set -e
#
# This script is meant for quick & easy install via:
#   curl -sSL https://raw.githubusercontent.com/HealthCatalyst/dos.install/master/onprem/setupnode.sh | bash
#
#

version="2018.04.16.02"
echo "---- setupnode version $version ----"

GITHUB_URL="https://raw.githubusercontent.com/HealthCatalyst/dos.install/master"
source <(curl -sSL "$GITHUB_URL/common/common.sh?p=$RANDOM")

createShortcutFordos $GITHUB_URL

SetupNewNode $GITHUB_URL

echo "---- finish setupnode version $version ----"