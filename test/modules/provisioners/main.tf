resource "null_resource" "this" {
  depends_on = [var.depends_on_instance_id]

  connection {
    type                = "ssh"
    user                = var.user
    private_key         = var.keypair
    host                = var.target_private_ip
    bastion_host        = var.bastion_public_ip
    bastion_user        = var.user
    bastion_private_key = var.keypair
  }

  provisioner "remote-exec" {
    inline = var.commands
  }

  triggers = {
    instance_id = var.trigger_instance_id
  }
}