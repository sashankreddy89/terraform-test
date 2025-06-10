region  = "eu-west-3"
pub_sub = ["10.0.1.0/24", "10.0.2.0/24"]
pvt_sub = ["10.0.3.0/24", "10.0.4.0/24"]
az      = ["a", "b"]
tags = {
  Environment = "dev"
  Project     = "chatapp"
  Owner       = "sashank"
}
frontend_ami   = "ami-0ff71843f814379b3"
backend_ami    = "ami-0ff71843f814379b3"
db_ami         = "ami-0160e8d70ebc43ee1"
instance_type  = "t2.micro"
key_name       = "chatapp-key-terraform"
key_filename       = "chatapp_key.pem"
