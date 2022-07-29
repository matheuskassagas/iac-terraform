#!/bin/bash

TERM=xterm-mono
SSHKEY="${HOME}/.ssh/id_rsa"


function logo() {
  clear
  echo -e "\n\t..:: Scripts ::..\n"
  echo -e "\t[ Ambiente AWS com WordPress ]\n"
  echo -e "\t\t+ S3 ( State Terraform )"
  echo -e "\t\t+ Network - VPC, Subnets (Private / Public), Route Tables, EIP, InterntGateway, NatGateway..."
  echo -e "\t\t+ RDS - MySQL 5.7"
  echo -e "\t\t+ Ec2 ( Docker, docker-compose )\n"
}

function envtfvars_default() {
  read -p "Deseja criar o arquivo de variáveis de ambientes do Terraform \"env.tfvars\"? [ S | n ]: " OP
  if [ -z "${OP}" ]; then
    OP="s"
  fi
  case ${OP} in
    [sSyY] )
      cat << EOF > ./env.tfvars
region = "us-east-1"

environment = "dev"

vpc_env_cidr = "10.1.0.0/16"
subnet_private_az1  = "10.1.0.0/20"
subnet_private_az2 = "10.1.16.0/20"
subnet_public_az1 = "10.1.48.0/20"
subnet_public_az2 = "10.1.64.0/20"

rds_database_mysql = "db_wordpress"
rds_username_mysql = "myuserwp"
rds_password_mysql = "s1x90b?h&9-XUzeJ@SV+"

instance_type = "t3.small"
EOF
      ;;
  esac
  unset OP
}

function chaves() {
  if [ ! -z "$1" ]; then
    CHAVE_PUBLICA="${HOME}/.ssh/$1.pub"
    if [ -f "${CHAVE_PUBLICA}" ]; then
      CHAVE=$(cat $CHAVE_PUBLICA)
      EMAIL=$(echo $CHAVE | cut -d" " -f3)
      cat << EOF >> ./env.tfvars

# ssh-keygen -t rsa -b 4096 -C "${EMAIL}"
# ex.: cat ~/.ssh/$1.pub
public_key = "${CHAVE}"
EOF
      SSHKEY="${HOME}/.ssh/$1"
    fi
  fi
}

function keyssh() {
  echo -e "\nListando diretório \"${HOME}/.ssh\":\n"
  ls ${HOME}/.ssh
  echo ""

  read -p "Deseja usar alguma chave listado acima? [ S | n ]: " OP
  if [ -z "${OP}" ]; then
    OP="s"
  fi
  case ${OP} in
    [sSyY] )
      read -p "Insira a chave privada: (ex. id_rsa): " KEYPRIV
      chaves ${KEYPRIV}
      ;;
    [nN] )
      read -p "Qual o seu email para criação da chave ssh? (ex.: fulano@hotmail.com) " EMAIL
      read -p "Digite o nome do aquivo chave ssh? (ex.: id_rsa_fulano) " NOME_ARQUIVO
      ssh-keygen -t rsa -b 4096 -C "${EMAIL}" -f "${HOME}/.ssh/${NOME_ARQUIVO}" -N ""
      chaves ${NOME_ARQUIVO}
      ;;
  esac
  unset OP
}


function s3state() {
  cd 01-S3-State
  terraform init
  terraform apply --var-file=../env.tfvars --auto-approve
#   terrform show 
  cd ..
}

function network_dev() {
  cd 02-Network-DEV
  terraform init
  terraform apply --var-file=../env.tfvars --auto-approve
  OUTPUT=$(terraform show)
  SNPvtAZ1=$(echo "${OUTPUT}" | grep "subnet_private_az1_id")
  SNPvtAZ2=$(echo "${OUTPUT}" | grep "subnet_private_az2_id")
  SNPubAZ1=$(echo "${OUTPUT}" | grep "subnet_public_az1_id")
  SNPubAZ2=$(echo "${OUTPUT}" | grep "subnet_public_az2_id")
  VPCID=$(echo "${OUTPUT}" | grep "vpc_env_id")
  sleep 0.5
  cd ..
  echo "" >> ./env.tfvars
  echo "# OUTPUT 02-Network-DEV" >> ./env.tfvars
  echo "${SNPvtAZ1}" >> ./env.tfvars
  echo "${SNPvtAZ2}" >> ./env.tfvars
  echo "${SNPubAZ1}" >> ./env.tfvars
  echo "${SNPubAZ2}" >> ./env.tfvars
  echo "${VPCID}" >> ./env.tfvars
}

function rds_dev() {
  cd 03-RDS-DEV
  terraform init
  terraform apply --var-file=../env.tfvars --auto-approve
  OUTPUT=$(terraform show)
  RDSEPMS=$(echo "${OUTPUT}" | grep "rds_endpoint_mysql")
  VPCSGID=$(echo "${OUTPUT}" | grep "vpc_security_group_ids")
  sleep 0.5
  cd ..
  cat << EOF >> ./env.tfvars

# OUTPUT 03-RDS-DEV
${RDSEPMS}
${VPCSGID}
EOF
}

function ec2_dev() {
  cd 04-Ec2-DEV
  terraform init
  terraform apply --var-file=../env.tfvars --auto-approve
  OUTPUT=$(terraform show)
  WPPIP=$(echo "${OUTPUT}" | grep "wordpress_dev_public_ip")
  WPPDNS=$(echo "${OUTPUT}" | grep "wordpress_dev_public_dns")
  sleep 0.5
  cd ..
  cat << EOF >> ./env.tfvars

# OUTPUT 04-Ec2-DEV
${WPPIP}
${WPPDNS}
EOF
}

function show_finale() {
  WPPIP=$(cat env.tfvars | grep "wordpress_dev_public_ip" |cut -d' ' -f3 | cut -d'"' -f2)
  WPPDNS=$(cat env.tfvars | grep "wordpress_dev_public_dns" |cut -d' ' -f3 | cut -d'"' -f2)

  echo -e "\nAcessos HTTP:\n"
  echo -e "\thttp://${WPPDNS}/"
  echo -e "\thttp://${WPPIP}/\n"

  echo -e "\nAcessos SSH:\n"
  echo -e "\tssh -i ${SSHKEY} ubuntu@${WPPDNS}"
  echo -e "\tssh -i ${SSHKEY} ubuntu@${WPPIP}\n"

  echo -e "\nSCP SSH:\n"
  echo -e "\tscp -i ${SSHKEY} DIR/file.txt ubuntu@${WPPDNS}:"
  echo -e "\tscp -i ${SSHKEY} DIR/file.txt ubuntu@${WPPIP}:\n"
  echo -e "\tscp -i ${SSHKEY} -r DIR ubuntu@${WPPDNS}:"
  echo -e "\tscp -i ${SSHKEY} -r DIR ubuntu@${WPPIP}:\n"
  echo -e "\tscp -i ${SSHKEY} ubuntu@${WPPDNS}:~/file.txt ."
  echo -e "\tscp -i ${SSHKEY} ubuntu@${WPPIP}:~/file.txt .\n"
  echo -e "\tscp -i ${SSHKEY} -r ubuntu@${WPPDNS}:~/DIR ."
  echo -e "\tscp -i ${SSHKEY} -r ubuntu@${WPPIP}:~/DIR .\n"
}


# #####################

function CreateENV() {
  envtfvars_default
  keyssh
  # s3state
  network_dev
  # rds_dev
  ec2_dev
  show_finale
}

function DestroyENV(){
  cd 04-Ec2-DEV
  terraform init
  terraform destroy --var-file=../env.tfvars --auto-approve
  cd ../03-RDS-DEV
  terraform init
  terraform destroy --var-file=../env.tfvars --auto-approve
  cd ../02-Network-DEV
  terraform init
  terraform destroy --var-file=../env.tfvars --auto-approve
  cd ../01-S3-State
  terraform init
  terraform destroy --var-file=../env.tfvars --auto-approve
  cd ..
  echo -e "\n\tFIM\n"
}
# #####################
# Inicio do Script

logo

echo -e "\t1 - Criar Ambiente AWS\n\t2 - Destruir Ambiente AWS\n"
read -p "opção: " OP
if [ -z "${OP}" ]; then
  OP="s"
fi
case ${OP} in
  1 )
    CreateENV
    ;;
  2 )
    DestroyENV
    ;;
esac


