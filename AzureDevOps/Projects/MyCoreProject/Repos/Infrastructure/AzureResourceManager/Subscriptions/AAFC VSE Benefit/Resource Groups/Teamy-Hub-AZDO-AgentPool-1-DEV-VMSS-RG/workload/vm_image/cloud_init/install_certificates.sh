echo "install_certificates.sh begin"
apt-get install -y ca-certificates
cp /usr/local/share/ca-certificates/GoC-GdC-Root-A.crt /etc/ssl/certs/
cp /usr/local/share/ca-certificates/GoC-GdC-Root-A.crt /etc/ssl/private/
update-ca-certificates
apt-get update
apt-get install -y apt-transport-https curl gnupg lsb-release unattended-upgrades software-properties-common unzip zip git npm
echo "install_certificates.sh end"
