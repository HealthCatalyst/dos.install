#!/bin/bash
# from http://redsymbol.net/articles/unofficial-bash-strict-mode/
# set -e option instructs bash to immediately exit if any command [1] has a non-zero exit status
# when set -u is set, a reference to any variable you haven't previously defined - with the exceptions of $* and $@ - is an error, and causes the program to immediately exit
# set -o pipefail: If any command in a pipeline fails, that return code will be used as the return code of the whole pipeline
set -euo pipefail

#
# This script is meant for quick & easy install via:
#   curl -sSL https://raw.githubusercontent.com/HealthCatalyst/dos.install/release/onprem/main.sh -o main.sh; bash main.sh
#   To test with the latest code on the master
#   curl -sSL https://raw.githubusercontent.com/HealthCatalyst/dos.install/master/onprem/main.sh -o main.sh; bash main.sh -prerelease
#   obsolete:
#   curl -sSL https://raw.githubusercontent.com/HealthCatalyst/dos.install/master/onprem/main.sh | bash
#   curl -sSL https://raw.githubusercontent.com/HealthCatalyst/dos.install/master/onprem/main.sh -o "${HOME}/main.sh"; bash "${HOME}/main.sh"
#   curl https://bit.ly/2GOPcyX | bash
#
version="2018.04.23.01"

prerelease=false
joincommand=""
if [[ "${1:-}" = "-prerelease" ]]; then
    echo "setting prerelease"
    prerelease=true
else
    echo "reading joincommand: $1"
    joincommand="$1"
fi

if [[ "${2:-}" = "-prerelease" ]]; then
    echo "setting prerelease"
    prerelease=true
fi
echo "joincommand = $joincommand"

GITHUB_URL="https://raw.githubusercontent.com/HealthCatalyst/dos.install/release"
if [[ "${prerelease:-false}" = true ]]; then
    GITHUB_URL="https://raw.githubusercontent.com/HealthCatalyst/dos.install/master"
    echo "-prerelease flag passed so switched GITHUB_URL to $GITHUB_URL"
fi

if [ ! -x "$(command -v yum)" ]; then
    echo "ERROR: yum command is not available"
    exit
fi

echo "CentOS version: $(cat /etc/redhat-release | grep -o '[0-9]\.[0-9]')"
echo "$(cat /etc/redhat-release)"

if [[ "$TERM" = "cygwin" ]]; then
    echo "Your TERM is set to cygwin.  We do not support this because it has issues in displaying text.  Please use a different SSH terminal e.g., MobaXterm"
    exit 1
fi

curl -sSL -o ./common.sh "$GITHUB_URL/common/common.sh?p=$RANDOM"
source ./common.sh

# source <(curl -sSL "$GITHUB_URL/common/common.sh?p=$RANDOM")
# source ./common/common.sh

# this sets the keyboard so it handles backspace properly
# http://www.peachpit.com/articles/article.aspx?p=659655&seqNum=13
echo "running stty sane to fix terminal keyboard mappings"
stty sane < /dev/tty

# echo "setting TERM to xterm"
# export TERM=xterm

echo "--- creating shortcut for dos ---"
createShortcutFordos $GITHUB_URL $prerelease

echo "--- installing prerequisites ---"
InstallPrerequisites

if [[ -z "$joincommand" ]]; then
    dos
else
    echo "--- download onprem-menu.ps1 ---"
    curl -o "${HOME}/onprem-menu.ps1" -sSL "${GITHUB_URL}/menus/onprem-menu.ps1?p=$RANDOM"

    echo "--- running onprem-menu.ps1 ---"
    pwsh -f "${HOME}/onprem-menu.ps1" -baseUrl $GITHUB_URL -joincommand "$joincommand"
fi

echo " --- end of main.sh $version ---"
