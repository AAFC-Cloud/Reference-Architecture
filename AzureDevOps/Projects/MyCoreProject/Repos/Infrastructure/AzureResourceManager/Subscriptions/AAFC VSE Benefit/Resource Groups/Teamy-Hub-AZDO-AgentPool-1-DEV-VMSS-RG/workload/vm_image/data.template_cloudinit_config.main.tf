data "template_cloudinit_config" "main" {
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content      = data.template_file.main.rendered
  }
}
