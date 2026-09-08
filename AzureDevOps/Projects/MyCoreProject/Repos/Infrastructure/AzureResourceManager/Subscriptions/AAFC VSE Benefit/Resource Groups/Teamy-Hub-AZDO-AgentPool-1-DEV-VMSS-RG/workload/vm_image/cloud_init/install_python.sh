#!/usr/bin/env bash
set -euo pipefail

echo "install_uv.sh begin"

export UV_INSTALL_DIR="/usr/local/bin"
export UV_NO_MODIFY_PATH=1
export UV_PYTHON_INSTALL_DIR="/opt/uv/python"
export UV_PYTHON_BIN_DIR="/usr/local/bin"
export UV_PYTHON_INSTALL_BIN=true

mkdir -p "$UV_PYTHON_INSTALL_DIR" /etc/uv
printf 'system-certs = true\n' > /etc/uv/uv.toml
chmod 0644 /etc/uv/uv.toml

curl -LsSf https://astral.sh/uv/install.sh | sh

uv python install 3.13 3.12 3.11 3.10 3.9
uv cache clean

echo "install_uv.sh end"
