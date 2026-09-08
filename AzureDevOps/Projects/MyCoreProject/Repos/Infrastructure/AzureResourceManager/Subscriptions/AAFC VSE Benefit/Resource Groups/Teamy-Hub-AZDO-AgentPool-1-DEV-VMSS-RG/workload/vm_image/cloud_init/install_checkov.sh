#!/usr/bin/env bash
set -euo pipefail

echo "install_checkov.sh begin"

UV_TOOL_DIR="/opt/uv/tools" \
UV_TOOL_BIN_DIR="/usr/local/bin" \
  uv tool install checkov
uv cache clean

echo "install_checkov.sh end"
