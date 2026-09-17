#!/usr/bin/env bash
set -euo pipefail

echo "install_terraform.sh begin"

# Azure DevOps agents normally run as a non-root user. Use non-interactive
# sudo for the system paths used below so the task cannot wait for a password
# prompt or an interactive shell.
if [[ "$(id -u)" -eq 0 ]]; then
  SUDO=()
else
  SUDO=(sudo -n)
fi

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
  "${SUDO[@]}" unzip -o "${TERRAFORM_ARCHIVE}" -d /usr/local/bin
  rm -f "${TERRAFORM_ARCHIVE}"
else
  # VMSS agents can run background apt operations during provisioning. Ask
  # apt-get to wait for the dpkg frontend lock instead of failing immediately.
  APT_LOCK_TIMEOUT="${APT_LOCK_TIMEOUT:-300}"

  "${SUDO[@]}" mkdir -p /etc/apt/keyrings
  curl -fsSL https://apt.releases.hashicorp.com/gpg \
    | "${SUDO[@]}" gpg --dearmor --yes -o /etc/apt/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    | "${SUDO[@]}" tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
  "${SUDO[@]}" chmod 0644 /etc/apt/sources.list.d/hashicorp.list
  "${SUDO[@]}" apt-get \
    -o "DPkg::Lock::Timeout=${APT_LOCK_TIMEOUT}" \
    update
  "${SUDO[@]}" env DEBIAN_FRONTEND=noninteractive apt-get \
    -o "DPkg::Lock::Timeout=${APT_LOCK_TIMEOUT}" \
    install -y terraform
fi

terraform version
echo "install_terraform.sh end"
