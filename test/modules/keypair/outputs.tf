output "key_name" {
  value = aws_key_pair.key.key_name
}

output "key_path" {
  value = local_file.save_private_key.filename
}

output "private_key_pem" {
    value = tls_private_key.chatapp_key.private_key_pem
}