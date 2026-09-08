#!/usr/bin/env bash
set -euo pipefail

echo "install_nodejs.sh begin"

NODE_VERSION="${NODE_VERSION:-24.19.0}"

case "$(dpkg --print-architecture)" in
  amd64) NODE_ARCH="x64" ;;
  arm64) NODE_ARCH="arm64" ;;
  *)
    echo "Unsupported Node.js architecture: $(dpkg --print-architecture)" >&2
    exit 1
    ;;
esac

NODE_ARCHIVE="/tmp/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.gz"
curl -fsSL \
  "https://nodejs.org/download/release/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.gz" \
  --output "${NODE_ARCHIVE}"
tar -xzf "${NODE_ARCHIVE}" -C /usr/local --strip-components=1
rm -f "${NODE_ARCHIVE}"

node --version
npm --version
echo "install_nodejs.sh end"
