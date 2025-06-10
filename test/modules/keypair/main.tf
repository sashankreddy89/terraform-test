resource "tls_private_key" "chatapp_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key" {
  key_name   = var.key_name
  public_key = tls_private_key.chatapp_key.public_key_openssh
}

resource "local_file" "save_private_key" {
  content         = tls_private_key.chatapp_key.private_key_pem
  filename        = "${path.module}/${var.key_filename}"
  file_permission = "0400"
}
