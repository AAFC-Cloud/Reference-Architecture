#!/bin/bash
echo "install_docker.sh begin"

echo "Installing Docker..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

echo "Enabling Docker..."
systemctl enable docker
systemctl start docker

echo "Ensure forwarding is persistent"
echo "net.ipv4.ip_forward=1" | tee /etc/sysctl.d/99-docker-forward.conf
sysctl -p /etc/sysctl.d/99-docker-forward.conf

echo "Enable the two-way street for the firewall for docker"
# Rule A: Let the containers talk to the world (Inserted at top)
nft insert rule inet filter forward iifname "docker0" oifname "eth0" counter accept
# Rule B: Let the world talk back to the containers (Inserted at top)
nft insert rule inet filter forward iifname "eth0" oifname "docker0" ct state established,related counter accept

echo "Write nft rules to disk so they survive a reboot"
# This captures the current running state (including default Azure rules) and saves them
bash -c 'nft list ruleset > /etc/nftables.conf'

echo "Restart nftables to verify configuration integrity"
systemctl restart nftables 

echo "install_docker.sh end"
