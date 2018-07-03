variable "public_key_path" {
  description = "Enter the path to the SSH Public Key to add to AWS."
  default     = "./tfchef_test.pub"                                   # Create your own keypair and replace
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-west-2"
}

variable "private_key_path" {
  description = "Enter the path to the SSH Private Key to run provisioner."
  default     = "./tfchef_test.pem"                                         # Create your own keypair and replace
}

# Amazon Linux2 AMIs (this has bugs when installing apache)
variable "aws_amzn2_amis" {
  default = {
    "ca-central-1" = "ami-c59818a1"
    "us-east-1"    = "ami-afd15ed0"
    "us-east-2"    = "ami-2a0f324f"
    "us-west-1"    = "ami-00d8c660"
    "us-west-2"    = "ami-31394949"
  }
}

# Amazon Linux 2018-03 AMIs
variable "aws_amzn_amis" {
  default = {
    "eu-west-3"    = "ami-cae150b7"
    "ca-central-1" = "ami-2f39bf4b"
    "us-east-1"    = "ami-467ca739"
    "us-east-2"    = "ami-976152f2"
    "us-west-1"    = "ami-46e1f226"
    "us-west-2"    = "ami-6b8cef13"
  }
}

variable "aws_ubuntu_amis" {
  default = {}
}

variable "instance_type" {
  description = "AWS AMI instance type"
  default     = "t2.micro"
}
