variable "depends_on_instance_id" {}
variable "user" {}
variable "target_private_ip" {}
variable "bastion_public_ip" {}
variable "commands" { 
    type = list(string) 
}
variable "keypair" {
    type = string
}
variable "trigger_instance_id"{
    type = string
}