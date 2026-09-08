#!/usr/bin/env bash
set -euo pipefail

echo "install_azure_functools.sh begin"
npm install -g azure-functions-core-tools@4 --unsafe-perm true
func --version
echo "install_azure_functools.sh end"
