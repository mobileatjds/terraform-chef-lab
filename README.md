# Terraform Chef Lab
More information to follow on setting up...

# Reproduce
As it stands currently, you will need to do a few things to make this work:

* Change variables as needed
* Terraform init, plan, apply

* Spin up an OpsWorks Chef Automate Service in the VPC created by Terraform
* Download starter kit & credentials

# Configure Chef Server
* (optional) scp starter kit to the 'workstation' to configure Chef server
* or
* install chefdk on your local box and configure Chef server

# Destroy/Create chefnode
* Navigate to main.tf and change the 'chefnode' so that it will be destroyed/created
* Be sure to configure the userdata.sh to your requirements
* You can invoke ./starterkit/userdata.sh but passing to the userdata in terraform resource
* Once the chef server has been configured, the chefnode will auto-associate and be provisioned