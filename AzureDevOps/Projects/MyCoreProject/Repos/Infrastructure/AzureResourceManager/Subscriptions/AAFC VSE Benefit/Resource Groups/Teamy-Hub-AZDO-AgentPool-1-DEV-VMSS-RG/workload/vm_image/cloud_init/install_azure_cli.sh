#!/usr/bin/env bash
set -euo pipefail

echo "install_azure_cli.sh begin"
curl -fsSL https://aka.ms/InstallAzureCLIDeb | bash
az version
echo "install_azure_cli.sh end"
