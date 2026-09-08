locals {
  marketplace_image = jsondecode(file("${path.module}/marketplace-image.json"))
}
