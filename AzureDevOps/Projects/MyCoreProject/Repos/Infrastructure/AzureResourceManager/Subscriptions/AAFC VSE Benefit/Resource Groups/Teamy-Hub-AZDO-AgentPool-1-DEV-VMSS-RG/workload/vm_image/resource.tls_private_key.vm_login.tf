resource "tls_private_key" "vm_login" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
