region = "us-east-1"

environment = "dev"

vpc_env_cidr = "10.1.0.0/16"
subnet_private_az1  = "10.1.0.0/20"
subnet_private_az2 = "10.1.16.0/20"
subnet_public_az1 = "10.1.48.0/20"
subnet_public_az2 = "10.1.64.0/20"

rds_database_mysql = "wordpress"
rds_username_mysql = "myuser"
rds_password_mysql = "MySQL2022"

# ex.: cat ~/.ssh/id_rsa.pub
public_key = 

# #########################################################################
# #########################################################################
# OUTPUTS

# OUTPUT 02-Network-DEV
subnet_private_az1_id = 
subnet_private_az2_id = 
subnet_public_az1_id = 
subnet_public_az2_id = 
vpc_env_id = 

# OUTPUT 03-RDS-DEV
rds_endpoint_mysql = 

# OUTPUT 04-Ec2-DEV
myinstance_env_public_dns = 
myinstance_env_public_ip = 
