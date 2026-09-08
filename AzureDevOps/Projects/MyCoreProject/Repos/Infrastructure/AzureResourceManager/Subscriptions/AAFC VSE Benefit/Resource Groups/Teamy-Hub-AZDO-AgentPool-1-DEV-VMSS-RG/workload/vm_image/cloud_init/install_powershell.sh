#!/usr/bin/env bash
set -euo pipefail

echo "install_powershell.sh begin"

. /etc/os-release
MICROSOFT_REPO_DEB="/tmp/packages-microsoft-prod.deb"

curl -fsSL \
  "https://packages.microsoft.com/config/ubuntu/${VERSION_ID}/packages-microsoft-prod.deb" \
  --output "${MICROSOFT_REPO_DEB}"
dpkg -i "${MICROSOFT_REPO_DEB}"
rm -f "${MICROSOFT_REPO_DEB}"

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y powershell

pwsh --version
echo "install_powershell.sh end"
