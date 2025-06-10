output "vpc_id" {
  value = module.chatapp-vpc.vpc_id
}

output "pub_sub_ids" {
  value = [module.chatapp-vpc.pub_subnet_ids[0], module.chatapp-vpc.pub_subnet_ids[1]]
}

output "pvt_sub_id" {
  value = [module.chatapp-vpc.pvt_subnet_ids[0], module.chatapp-vpc.pvt_subnet_ids[1]]
}

output "frontend_sg_id" {
  value = module.frontend_sg.sg_id
}

output "backend_sg_id" {
  value = module.backend_sg.sg_id
}

output "database_sg_id" {
  value = module.database_sg.sg_id
}

output "frontend_public_ip" {
    value = module.frontend.public_ip
}
