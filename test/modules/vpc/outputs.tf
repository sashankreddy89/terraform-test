output "pub_subnet_ids" {
  value = aws_subnet.pub_sub[*].id
}

output "pvt_subnet_ids" {
  value = aws_subnet.pvt_sub[*].id
}

output "vpc_id" {
  value = aws_vpc.my_vpc.id
}