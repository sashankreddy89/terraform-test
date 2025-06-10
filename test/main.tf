# VPC Setup

module "chatapp-vpc" {
  source  = "./modules/vpc"
  pub_sub = var.pub_sub
  pvt_sub = var.pvt_sub
  az      = var.az
  tags    = var.tags
  region  = var.region
}


module "frontend_sg" {
  source      = "./modules/security-groups"
  name        = "frontend-sg"
  description = "Security group for frontend"
  vpc_id      = module.chatapp-vpc.vpc_id
  tags        = var.tags

  ingress_rules = [
    {
      description = "Allow ssh from my IP"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Allow HTTP"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  egress_rules = [
    {
      description = "Allow all outbound"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

module "backend_sg" {
  source      = "./modules/security-groups"
  name        = "backend-sg"
  description = "Security group for backend"
  vpc_id      = module.chatapp-vpc.vpc_id
  tags        = var.tags

  ingress_rules = [
    {
      description     = "Allow SSH from frontend"
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      security_groups = [module.frontend_sg.sg_id]
    },
    {
      description     = "Allow HTTP on 8000 from frontend"
      from_port       = 8000
      to_port         = 8000
      protocol        = "tcp"
      security_groups = [module.frontend_sg.sg_id]
    }
  ]

  egress_rules = [
    {
      description = "Allow all outbound"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

module "database_sg" {
  source      = "./modules/security-groups"
  name        = "database-sg"
  description = "Security group for database"
  vpc_id      = module.chatapp-vpc.vpc_id
  tags        = var.tags

  ingress_rules = [
    {
      description     = "Allow SSH from frontend"
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      security_groups = [module.frontend_sg.sg_id]
    },
    {
      description     = "Allow MySQL from backend"
      from_port       = 3306
      to_port         = 3306
      protocol        = "tcp"
      security_groups = [module.backend_sg.sg_id]
    }
  ]

  egress_rules = [
    {
      description = "Allow all outbound"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

module "chatapp_keypair" {
  source        = "./modules/keypair"
  key_name      = var.key_name
  key_filename  = var.key_filename
}


module "frontend" {
  source             = "./modules/ec2"
  ami                = var.frontend_ami
  instance_type      = var.instance_type
  subnet_id          = module.chatapp-vpc.pub_subnet_ids[0] 
  security_group_ids = [module.frontend_sg.sg_id]
  key_name           = var.key_name
  tags               = { Name = "chatapp-frontend" }
}

module "backend" {
  source             = "./modules/ec2"
  ami                = var.backend_ami
  instance_type      = var.instance_type
  subnet_id          = module.chatapp-vpc.pvt_subnet_ids[0]
  security_group_ids = [module.backend_sg.sg_id]
  key_name           = var.key_name
  tags               = { Name = "chatapp-backend" }
}

module "database" {
  source             = "./modules/ec2"
  ami                = var.db_ami
  instance_type      = var.instance_type
  subnet_id          = module.chatapp-vpc.pvt_subnet_ids[0]
  security_group_ids = [module.database_sg.sg_id]
  key_name           = var.key_name
  tags               = { Name = "chatapp-database" }
}

module "provision_mysql" {
  source                 = "./modules/provisioners"
  depends_on_instance_id = [module.database,module.frontend,module.chatapp-vpc]
  user                   = "ubuntu"
  keypair                = module.chatapp_keypair.private_key_pem
  target_private_ip      = module.database.private_ip
  bastion_public_ip      = module.frontend.public_ip
  trigger_instance_id    = module.database.instance_id
  commands = [
    "sudo apt update -y",
    "sudo DEBIAN_FRONTEND=noninteractive apt install mysql-server -y",
    "sudo sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf",
    "sudo systemctl restart mysql",
    "sudo mysql -e \"create user 'chatapp_user'@'%' identified by 'chatapp';\"",
    "sudo mysql -e \"create database chatapp_db;\"",
    "sudo mysql -e \"grant all privileges on chatapp_db.* to 'chatapp_user'@'%';\""
  ]
}

module "provision_django" {
  source                 = "./modules/provisioners"
  depends_on_instance_id = [module.backend,module.frontend,module.database,module.chatapp-vpc]
  user                   = "ubuntu"
  keypair                = module.chatapp_keypair.private_key_pem
  target_private_ip      = module.backend.private_ip
  bastion_public_ip      = module.frontend.public_ip
  trigger_instance_id    = module.backend.instance_id
  commands = [
    # dependencies
      "sudo DEBIAN_FRONTEND=noninteractive apt update -y",
      "sudo DEBIAN_FRONTEND=noninteractive apt install -y software-properties-common",
      "sudo add-apt-repository -y ppa:deadsnakes/ppa",
      "sudo DEBIAN_FRONTEND=noninteractive apt update -y",
      "sudo DEBIAN_FRONTEND=noninteractive apt install -y python3.8 python3.8-venv python3.8-dev git",
      "sudo DEBIAN_FRONTEND=noninteractive apt install -y pkg-config python3-dev default-libmysqlclient-dev build-essential",


      # clone
      "cd /home/ubuntu && git clone https://github.com/ARPIT226/chat_app.git",

      # env vars
      "echo 'DB_NAME=\"chatapp_db\"' | sudo tee -a /etc/environment",
      "echo 'DB_USER=\"chatapp_user\"' | sudo tee -a /etc/environment",
      "echo 'DB_PASSWORD=\"chatapp\"' | sudo tee -a /etc/environment",
      "echo 'DB_HOST=${module.database.private_ip}' | sudo tee -a /etc/environment",
      "export $(cat /etc/environment | xargs)",

      # venv
      "cd /home/ubuntu && python3.8 -m venv venv",
      ". /home/ubuntu/venv/bin/activate && pip install -r /home/ubuntu/chat_app/requirements.txt",
      ". /home/ubuntu/venv/bin/activate && pip install mysqlclient",

      # migrations
      "cd /home/ubuntu/chat_app/fundoo && . /home/ubuntu/venv/bin/activate && python manage.py makemigrations",
      "cd /home/ubuntu/chat_app/fundoo && . /home/ubuntu/venv/bin/activate && python manage.py migrate",

      # systemd for gunicorn
      "echo '[Unit]\\nDescription=Gunicorn service for chatapp\\nAfter=network.target\\n\\n[Service]\\nUser=ubuntu\\nWorkingDirectory=/home/ubuntu/chat_app/fundoo\\nEnvironmentFile=/etc/environment\\nExecStart=/home/ubuntu/venv/bin/gunicorn fundoo.wsgi:application --bind 0.0.0.0:8000\\nRestart=always\\n\\n[Install]\\nWantedBy=multi-user.target' | sudo tee /etc/systemd/system/chatapp.service",

      # Gunicorn reload and start
      "sudo systemctl daemon-reexec",
      "sudo systemctl daemon-reload",
      "sudo systemctl start chatapp",
      "sudo systemctl enable chatapp",
      "sudo systemctl status chatapp --no-pager"
  ]
}

module "provision_nginx" {
  source                 = "./modules/provisioners"
  depends_on_instance_id = [module.frontend,module.backend,module.chatapp-vpc]
  user                   = "ubuntu"
  keypair                = module.chatapp_keypair.private_key_pem
  target_private_ip      = module.frontend.public_ip
  bastion_public_ip      = null
  trigger_instance_id    = module.frontend.instance_id
  commands = [
    "sudo apt update -y",
    "sudo apt install -y nginx",
    "echo 'server {\n  listen 80;\n  location / {\n    proxy_pass http://${module.backend.private_ip}:8000;\n  }\n}' | sudo tee /etc/nginx/sites-available/chatapp",
    "sudo ln -s /etc/nginx/sites-available/chatapp /etc/nginx/sites-enabled/chatapp",
    "sudo rm -f /etc/nginx/sites-enabled/default",
    "sudo nginx -t",
    "sudo systemctl restart nginx",
    "sudo systemctl enable nginx"
  ]
}
