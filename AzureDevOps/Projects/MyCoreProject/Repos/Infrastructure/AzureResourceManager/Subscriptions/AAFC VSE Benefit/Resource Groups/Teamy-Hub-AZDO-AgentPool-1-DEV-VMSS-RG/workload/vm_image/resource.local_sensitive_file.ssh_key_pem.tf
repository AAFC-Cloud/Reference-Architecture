resource "local_sensitive_file" "ssh_key_pem" {
  filename             = "${path.module}/ignore/sshkey.pem"
  content              = tls_private_key.vm_login.private_key_pem
  directory_permission = "0700"
  file_permission      = "0600"
}
