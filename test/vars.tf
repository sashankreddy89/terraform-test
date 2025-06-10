variable "pub_sub" {
  description = "Contains the public subnets cidr"
  type        = list(string)
}

variable "pvt_sub" {
  description = "Contains the private subnets cidr"
  type        = list(string)
}

variable "az" {
  description = "contains the list of azs"
  type        = list(string)
}

variable "region" {
  description = "Region used"
  type        = string
}

variable "tags" {
  description = "Contains all the common tags"
  type        = map(string)
}

variable "frontend_ami" {

}
variable "backend_ami" {}
variable "db_ami" {}
variable "instance_type" {}
variable "key_name" {}
variable "key_filename" {}
