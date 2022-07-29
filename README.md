# Infra Projeto Ecommerc

- Processo automatizado para construção de um servidor web para
WordPress em sua última versão.

## Sequencia de apply terraform

- Ambiente DEV
  - 01-S3-State
  - 02-Network-DEV
  - 03-RDS-DEV
  - 04-Ec2-DEV

## ~ EXECUÇÃO AUTOMATICA ~
```
./wordpress_env.sh
```

## ~ EXECUÇÃO MANUAL ~

## Criar chave rsa

```bash
ssh-keygen -t rsa -b 4096 -C "email_do_github"
cat ~/.ssh/id_rsa_wordpress.pub
```

logo em seguida adicionar a chave pública ao arquivo *env.tfvars* na variável *public_key*

## S3-State

- Script Terraform com persistência no S3

```bash
cd 01-S3-State

terraform init
terraform plan --var-file=../env.tfvars
terraform apply --var-file=../env.tfvars
```

**Se quiser destruir**:

```bash
terraform destroy --var-file=../env.tfvars
```

## Network

```bash
cd ..
cd 02-Network

terraform init
terraform plan --var-file=../env.tfvars
terraform apply --var-file=../env.tfvars
```

-IMPORTANTE: Pegar Outputs e adicionar ao arquivo *env.tfvars* nas variáveis *subnets...*, exemplo:

```bash
subnet_private_az1_id = "subnet-0aff571efcb86a524"
subnet_private_az2_id = "subnet-04a43817c318b8e0a"
subnet_public_az1_id = "subnet-04b950c56b23615e6"
subnet_public_az2_id = "subnet-07e4ae2cbc5e923a9"
vpc_env_id = "vpc-00732e71af954342b"
```

**Se quiser destruir**:

```bash
terraform destroy --var-file=../env.tfvars
```

## RDS

```bash
cd ..
cd 03-RDS-DEV

terraform init
terraform plan --var-file=../env.tfvars
terraform apply --var-file=../env.tfvars
```

**Se quiser destruir**:

```bash
terraform destroy --var-file=../env.tfvars
```

## EC2

```bash
cd ..
cd 04-Ec2-DEV

terraform init
terraform plan --var-file=../env.tfvars
terraform apply --var-file=../env.tfvars
```

-IMPORTANTE: Pegar Outputs e adicionar ao arquivo *env.tfvars* na variáveis *wordpress*, exemplo:

```bash
wordpress_dev_public_dns = "ec2-52-9-164-90.us-west-1.compute.amazonaws.com"
wordpress_dev_public_ip = "52.9.164.90"
```

**Se quiser destruir**:

```bash
terraform destroy --var-file=../env.tfvars
```

## TERRAFORM itens adicionados

- S3 [ Bucket - State ]
- Network [ VPC, Subnets, Internet Gateway, NAT Gateway, Route Table ]
- RDS-MySQL [ Instance, SG]
- EC2  [ EC2, SG, EIP ]

### ec2

- name: myInstance;
- instance type: t2.micro;
- AZ: us-east-1
- AMI: ami-0d57c0143330e1fa7;
- VPC: default
    443  TCP 0.0.0.0/0
    80   TCP 0.0.0.0/0
    22   TCP 0.0.0.0/0
    8080 TCP 0.0.0.0/0
- subnet-public-az1: "10.1.48.0/20"
- Elastic IP: yes;

### Bucket-s3-State

   wordpress-state
   us-east-1
   privado

### VPC

- "0.1.0.0/16"
    - subnet-private-az1 = "10.1.0.0/20" RDS
    - subnet-private-az2 = "10.1.16.0/20" RDS
    - subnet-public-az1  = "10.1.48.0/20" ec2
    - subnet-public-az2  = "10.1.64.0/20"

### Security Groups

**Grupo 01: ec2**:

- name: sg_dev_ec2_wordpress;
- regras de entrada: 3 Entrada de permissão
    - 22
    - 443
    - 80
    - 8080
- regras de saída: 1 Entrada de permissão
    - 0.0.0.0/0

**Grupo 02: RDS**:

- name: sg_dev_rds_mysql;
- regras de entrada: 1 entrada de permissão
    - 3306
- regras de saída:
    - 0.0.0.0/0

### RDS

- name: rds-prd-mysql;
- engine: mySQL;
- AZ: us-east-1;
- VPC:
    - subnet-private-az1 = "10.1.0.0/20"
    - subnet-private-az2 = "10.1.16.0/20"
- type_instance: db.t3.small;
- engine_version: 5.7;
