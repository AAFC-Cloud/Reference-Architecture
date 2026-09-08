#!/usr/bin/env bash
set -euo pipefail

echo "install_java.sh begin"

JAVA_VERSION="21"

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y "openjdk-${JAVA_VERSION}-jdk"

JAVA_HOME="$(dirname "$(dirname "$(readlink -f "$(command -v javac)")")")"
update-alternatives --set java "${JAVA_HOME}/bin/java"
update-alternatives --set javac "${JAVA_HOME}/bin/javac"

printf 'export JAVA_HOME="%s"\nexport PATH="${JAVA_HOME}/bin:${PATH}"\n' "${JAVA_HOME}" > /etc/profile.d/java.sh
chmod 0644 /etc/profile.d/java.sh

if grep -q '^JAVA_HOME=' /etc/environment; then
  sed -i "s|^JAVA_HOME=.*|JAVA_HOME=${JAVA_HOME}|" /etc/environment
else
  printf '\nJAVA_HOME=%s\n' "${JAVA_HOME}" >> /etc/environment
fi

echo "JAVA_HOME=${JAVA_HOME}"
java -version
echo "install_java.sh end"