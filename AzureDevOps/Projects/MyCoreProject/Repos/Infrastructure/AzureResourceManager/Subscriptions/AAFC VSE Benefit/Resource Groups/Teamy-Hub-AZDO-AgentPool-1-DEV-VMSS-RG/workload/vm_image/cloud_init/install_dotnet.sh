#!/usr/bin/env bash
set -euo pipefail

echo "install_dotnet.sh begin"

DOTNET_VERSION="10.0"

. /etc/os-release
if [ "${ID}" != "ubuntu" ]; then
  echo "This installer supports Ubuntu only; detected ${ID}." >&2
  exit 1
fi

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl

MICROSOFT_REPO_DEB="/tmp/packages-microsoft-prod.deb"
curl -fsSL \
  "https://packages.microsoft.com/config/ubuntu/${VERSION_ID}/packages-microsoft-prod.deb" \
  --output "${MICROSOFT_REPO_DEB}"
dpkg -i "${MICROSOFT_REPO_DEB}"
rm -f "${MICROSOFT_REPO_DEB}"

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  "dotnet-sdk-${DOTNET_VERSION}" \
  "aspnetcore-runtime-${DOTNET_VERSION}"

dotnet --list-sdks
dotnet --list-runtimes
echo "install_dotnet.sh end"