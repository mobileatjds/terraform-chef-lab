####################################################
#   Slalom Demo - leveraging IaC, Terraform & Chef #
####################################################

#
# Provider. We assume access keys are provided via environment variables.
#

provider "aws" {
  region = "${var.aws_region}"
}

#
# Network. We create a VPC, gateway, subnets and security groups.
#

resource "aws_vpc" "vpc_chef_main" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name = "Main Chef VPC"
  }
}

resource "aws_internet_gateway" "tfchef-igw" {
  vpc_id = "${aws_vpc.vpc_chef_main.id}"
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.vpc_chef_main.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.tfchef-igw.id}"
}

# Create a public subnet to launch our load balancers
resource "aws_subnet" "public" {
  vpc_id                  = "${aws_vpc.vpc_chef_main.id}"
  cidr_block              = "10.0.1.0/24"                 # 10.0.1.0 - 10.0.1.255 (256)
  map_public_ip_on_launch = true
}

# Create a private subnet to launch our backend instances
resource "aws_subnet" "private" {
  vpc_id                  = "${aws_vpc.vpc_chef_main.id}"
  cidr_block              = "10.0.16.0/20"                # 10.0.16.0 - 10.0.31.255 (4096)
  map_public_ip_on_launch = false
}

# Our default security group to access the instances over SSH and HTTP
resource "aws_security_group" "tfchef" {
  name        = "tfchef-sg"
  description = "Security group for backend servers and private ELBs"
  vpc_id      = "${aws_vpc.vpc_chef_main.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Change this to your current IP/32
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access from the world
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all from private subnet
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${aws_subnet.private.cidr_block}"]
  }

  # Allow all from public subnet
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${aws_subnet.public.cidr_block}"]
  }

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#
# The key pair which will be installed on the instances later.
#

resource "aws_key_pair" "auth" {
  key_name   = "tfchef_key"
  public_key = "${file(var.public_key_path)}"
}

#
# Instances to deploy in environment
#

resource "aws_instance" "chefnode" {
  instance_type          = "${var.instance_type}"
  ami                    = "${lookup(var.aws_amzn_amis, var.aws_region)}"
  key_name               = "${aws_key_pair.auth.id}"
  vpc_security_group_ids = ["${aws_security_group.tfchef.id}"]
  subnet_id              = "${aws_subnet.public.id}"
  iam_instance_profile   = "aws-opsworks-chefauto-auto-add-node"          # ensure this role is present
  user_data              = "${file("./install.sh")}"

  tags {
    Name = "ChefNode"
  }

  # Provisioning
  connection {
    user        = "ec2-user"
    private_key = "${file(var.private_key_path)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum -y update && sudo yum -y upgrade",
    ]
  }
}

resource "aws_instance" "chef-local" {
  instance_type          = "${var.instance_type}"
  ami                    = "${lookup(var.aws_amzn_amis, var.aws_region)}"
  key_name               = "${aws_key_pair.auth.id}"
  vpc_security_group_ids = ["${aws_security_group.tfchef.id}"]
  subnet_id              = "${aws_subnet.public.id}"

  tags {
    Name = "chef-local-workstation"
  }

  # Provisioning
  connection {
    user        = "ec2-user"
    private_key = "${file(var.private_key_path)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum -y update && sudo yum -y upgrade",
      "wget https://packages.chef.io/files/stable/chefdk/3.0.36/el/7/chefdk-3.0.36-1.el7.x86_64.rpm",
      "sudo rpm -Uvh chefdk-3.0.36-1.el7.x86_64.rpm",
    ]
  }
}
