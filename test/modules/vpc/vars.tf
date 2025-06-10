variable "cidr"{
    description="CIDR block used for the VPC"
    type = string
    default = "10.0.0.0/16"
}

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

variable "tags" {
  description = "Common tags for all resources"
  type = map(string)
}

variable "region" {
    description = "region for az"
    type = string
}
