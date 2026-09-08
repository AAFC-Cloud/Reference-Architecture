#!/usr/bin/env bash
set -euo pipefail

echo "install_terraform.sh begin"

if [[ -n "${TERRAFORM_VERSION:-}" ]]; then
  case "$(dpkg --print-architecture)" in
    amd64) TERRAFORM_ARCH="amd64" ;;
    arm64) TERRAFORM_ARCH="arm64" ;;
    *)
      echo "Unsupported Terraform architecture: $(dpkg --print-architecture)" >&2
      exit 1
      ;;
  esac

  TERRAFORM_ARCHIVE="/tmp/terraform_${TERRAFORM_VERSION}_linux_${TERRAFORM_ARCH}.zip"
  curl -fsSL \
    "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TERRAFORM_ARCH}.zip" \
    --output "${TERRAFORM_ARCHIVE}"
  unzip -o "${TERRAFORM_ARCHIVE}" -d /usr/local/bin
  rm -f "${TERRAFORM_ARCHIVE}"
else
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://apt.releases.hashicorp.com/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/hashicorp.list
  chmod 0644 /etc/apt/sources.list.d/hashicorp.list
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y terraform
fi

terraform version
echo "install_terraform.sh end"
