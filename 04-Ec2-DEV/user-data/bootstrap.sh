#!/bin/sh

# ${VAR_RDS_ENDPOINT}
# ${VAR_RDS_USERNAME}
# ${VAR_RDS_PASSWORD}
# ${VAR_RDS_DATABASE}
# ${VAR_PORT_SSH}
# ${VAR_DIR_CLOUD}
# ${VAR_DIR_NGINX}

apt update && sudo apt install docker.io docker-compose -y 

# #################################
# Modificando a porta do SSH

if [ "${VAR_PORT_SSH}" != "22" ]; then
  sed -i s/"#Port 22"/"Port ${VAR_PORT_SSH}"/g /etc/ssh/sshd_config
  sudo systemctl reload sshd
  # # semanage port -a -t ssh_port_t -p tcp ${VAR_PORT_SSH}
  # # firewall-cmd --zone=public --add-port=${VAR_PORT_SSH}/tcp --permanent
  # # firewall-cmd --reload
fi

# # #################################
# # 
# cat << EOF > /usr/local/sbin/ssl_gen.sh
# #!/bin/bash
# FQDN=\$1

# # make directories to work from
# mkdir -p certs/{server,client,ca,tmp}

# # Create your very own Root Certificate Authority
# openssl genrsa \\
#   -out certs/ca/my-root-ca.key.pem \\
#   2048

# # Self-sign your Root Certificate Authority
# # Since this is private, the details can be as bogus as you like
# openssl req \\
#   -x509 \\
#   -new \\
#   -nodes \\
#   -key certs/ca/my-root-ca.key.pem \\
#   -days 1024 \\
#   -out certs/ca/my-root-ca.crt.pem \\
#   -subj "/C=US/ST=Utah/L=Provo/O=ACME Signing Authority Inc/CN=example.com"

# # Create a Device Certificate for each domain,
# # such as example.com, *.example.com, awesome.example.com
# # NOTE: You MUST match CN to the domain name or ip address you want to use
# openssl genrsa \\
#   -out certs/server/privkey.pem \\
#   2048

# # Create a request from your Device, which your Root CA will sign
# openssl req -new \\
#   -key certs/server/privkey.pem \\
#   -out certs/tmp/csr.pem \\
#   -subj "/C=US/ST=Utah/L=Provo/O=ACME Tech Inc/CN=\$\{FQDN\}"

# # Sign the request from Device with your Root CA
# # -CAserial certs/ca/my-root-ca.srl
# openssl x509 \\
#   -req -in certs/tmp/csr.pem \\
#   -CA certs/ca/my-root-ca.crt.pem \\
#   -CAkey certs/ca/my-root-ca.key.pem \\
#   -CAcreateserial \\
#   -out certs/server/cert.pem \\
#   -days 500

# # Create a public key, for funzies
# # see https://gist.github.com/coolaj86/f6f36efce2821dfb046d
# openssl rsa \\
#   -in certs/server/privkey.pem \\
#   -pubout -out certs/client/pubkey.pem

# # Put things in their proper place
# rsync -a certs/ca/my-root-ca.crt.pem certs/server/chain.pem
# rsync -a certs/ca/my-root-ca.crt.pem certs/client/chain.pem
# cat certs/server/cert.pem certs/server/chain.pem > certs/server/fullchain.pem
# EOF
# chmod +x /usr/local/sbin/ssl_gen.sh


# #################################
# 
if [ ! -d "${VAR_DIR_CLOUD}" ]; then
  mkdir ${VAR_DIR_CLOUD}
  echo '# ${VAR_RDS_ENDPOINT}
# ${VAR_RDS_USERNAME}
# ${VAR_RDS_PASSWORD}
# ${VAR_RDS_DATABASE}
# ${VAR_PORT_SSH}
# ${VAR_DIR_CLOUD}
# ${VAR_DIR_NGINX}' > ${VAR_DIR_CLOUD}/.env
fi

# ##################################################################
# # Criando o diretório nginx e seus arquivos de configurações
# # 
# if [ ! -d "${VAR_DIR_NGINX}" ]; then
#   mkdir ${VAR_DIR_NGINX}
#   cd ${VAR_DIR_NGINX}

#   cat << EOF > ${VAR_DIR_NGINX}/default.conf
# # redirect to HTTPS
# server {
#     listen 80;
#     listen [::]:80;
#     server_name \$host;
#     location / {
#         # update port as needed for host mapped https
#         rewrite ^ https://\$host\$request_uri? permanent;
#     }
# }

# server {
#     listen 443 ssl http2;
#     listen [::]:443 ssl http2;
#     server_name \$host;
#     index index.php index.html index.htm;
#     root /var/www/html;
#     server_tokens off;
#     client_max_body_size 75M;

#     # update ssl files as required by your deployment
#     ssl_certificate /etc/ssl/fullchain.pem;
#     ssl_certificate_key /etc/ssl/privkey.pem;

#     # logging
#     access_log /var/log/nginx/wordpress.access.log;
#     error_log /var/log/nginx/wordpress.error.log;

#     # some security headers ( optional )
#     add_header X-Frame-Options "SAMEORIGIN" always;
#     add_header X-XSS-Protection "1; mode=block" always;
#     add_header X-Content-Type-Options "nosniff" always;
#     add_header Referrer-Policy "no-referrer-when-downgrade" always;
#     add_header Content-Security-Policy "default-src * data: 'unsafe-eval' 'unsafe-inline'" always;

#     location / {
#         try_files \$uri \$uri/ /index.php\$is_args\$args;
#     }

#     location ~ \.php\$ {
#         try_files \$uri = 404;
#         fastcgi_split_path_info ^(.+\.php)(/.+)\$;
#         fastcgi_pass wordpress:8080;
#         fastcgi_index index.php;
#         include fastcgi_params;
#         fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
#         fastcgi_param PATH_INFO \$fastcgi_path_info;
#     }

#     location ~ /\.ht {
#         deny all;
#     }

#     location = /favicon.ico {
#         log_not_found off; access_log off;
#     }

#     location = /favicon.svg {
#         log_not_found off; access_log off;
#     }

#     location = /robots.txt {
#         log_not_found off; access_log off; allow all;
#     }

#     location ~* \.(css|gif|ico|jpeg|jpg|js|png)\$ {
#         expires max;
#         log_not_found off;
#     }
# }
# EOF

#   cat << EOF > ${VAR_DIR_NGINX}/Dockerfile
# FROM nginx:stable-alpine
# COPY default.conf /etc/nginx/conf.d
# EXPOSE 80/tcp
# EXPOSE 443/tcp
# CMD ["/bin/sh", "-c", "exec nginx -g 'daemon off;';"]
# WORKDIR /usr/share/nginx/html
# EOF
# fi

# ##################################################################
# Criando o arquivo docker-compose.yml
# 
cd ${VAR_DIR_CLOUD}

cat << EOF > ${VAR_DIR_CLOUD}/docker-compose.yml
version: "3.1"
services:
  wordpress:
    container_name: wordpress
    image: wordpress
    restart: always
    ports:
      - 80:80
    # depends_on:
    #   - mysql
    environment:
      WORDPRESS_DB_HOST: ${VAR_RDS_ENDPOINT}
      WORDPRESS_DB_USER: ${VAR_RDS_USERNAME}
      WORDPRESS_DB_PASSWORD: ${VAR_RDS_PASSWORD}
      WORDPRESS_DB_NAME: ${VAR_RDS_DATABASE}
    volumes:
      - ${VAR_DIR_CLOUD}/wordpress:/var/www/html
    networks:
      - mynet
  mysql:
    container_name: mysql
    image: mysql:5.7
    restart: always
    environment:
      MYSQL_DATABASE: ${VAR_RDS_DATABASE}
      MYSQL_USER: ${VAR_RDS_USERNAME}
      MYSQL_PASSWORD: ${VAR_RDS_PASSWORD}
      MYSQL_RANDOM_ROOT_PASSWORD: '1'
    volumes:
      - ${VAR_DIR_CLOUD}/mysqldb:/var/lib/mysql
    networks:
      - mynet
  # nginx:
  #   image: nginx-reverse-proxy
  #   container_name: nginx
  #   restart: always
  #   depends_on:
  #     - wordpress
  #   ports:
  #     - 80:80
  #     - 443:443
  #   volumes:
  #     - ${VAR_DIR_CLOUD}/nginx/default.conf:/etc/nginx/conf.d/default.conf
  #     - ${VAR_DIR_CLOUD}/certs/server/:/etc/ssl/
  #   networks:
  #     - mynet
networks:
    mynet:
EOF

# ##############
sleep 1
usermod -aG docker ubuntu

sleep 1
cd ${VAR_DIR_CLOUD}

# sleep 1
# ssl_gen.sh "wordpress.CLOUD.com.br"

sleep 1
# docker build -t nginx-reverse-proxy:latest nginx/.
docker-compose up -d
Footer
