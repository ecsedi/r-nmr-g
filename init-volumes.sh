#!/bin/bash

set -e

MARIADB_IMAGE='mariadb:10.7.3'
NGINX_IMAGE="nginx:latest"

. .env

cd $(dirname $(realpath "$0"))

# Check guacamole password.

if ( echo "$GUACAMOLE_DB_PASSWORD" | egrep -q '^[a-zA-Z0-9_.-]+$' ); then
  :
else
  echo "Invalid GUACAMOLE_DB_PASSWORD '$GUACAMOLE_DB_PASSWORD' in docker.env." >&2
  echo "Use only letters, digits, dot, hyphen and underscore."                 >&2
  exit 1
fi

# Set up initial database.

if [ -n "$(ls -A volumes/guadb/var/lib/mysql/)" ]; then

  echo "Found an existing database in volumes/guadb/var/lib/mysql."
  echo "Please remove it first if you intend to create a new one."
  echo ""

else

  echo "Initializing database in volumes/guadb/var/lib/mysql."

  now=$(date '+%Y%m%d%H%M%S')
  mariadb_container="guadb_init_$now"

  echo "Starting database container."
  docker run                                                   \
    --name "$mariadb_container"                                \
    --rm                                                       \
    -d                                                         \
    -v "$(pwd)/volumes/guadb/var/lib/mysql/":"/var/lib/mysql/" \
    -v "$(pwd)/volumes/init/":"/volumes/init/"                 \
    -e MARIADB_ROOT_PASSWORD="$MARIADB_ROOT_PASSWORD"          \
    "$MARIADB_IMAGE"

  echo "Waiting for mariadb to start..."
  ready="no"
  while [ "$ready" != "yes" ]; do
    sleep 1
    n=$(docker logs "$mariadb_container" 2>&1 | fgrep 'mariadbd: ready for connections.' | wc -l)
    if [ "$n" = "2" ]; then
      ready="yes"
    fi
  done

  echo "Initializing guacamole database."
  docker container exec "$mariadb_container" /volumes/init/mysql-init.sh "$MARIADB_ROOT_PASSWORD" "$GUACAMOLE_DB_PASSWORD"
  sleep 1

  echo "Stopping database container."
  docker container stop "$mariadb_container"

fi

# Set up nginx reverse proxy configuration.

if [ -e volumes/nginx/etc/nginx/conf.d/default.conf ]; then

  echo "Found an existing nginx configuration in volumes/nginx/etc/nginx/conf.d/default.conf."
  echo "Please remove it first if you intend to create a new one."
  echo ""

else

  echo "Creating nginx configuration volumes/nginx/etc/nginx/conf.d/default.conf."

  if [ -n "$HTTPS_PORT" ]; then

    cat <<ENDCONFIG_SSL > volumes/nginx/etc/nginx/conf.d/default.conf
server {
    listen      80;
    listen [::]:80;

    server_name   $DOMAIN_NAME;
    server_tokens off;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$DOMAIN_NAME$request_uri;
    }
}

server {
    listen      443 default_server ssl http2;
    listen [::]:443                ssl http2;

    server_name $DOMAIN_NAME;

    ssl_certificate     /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem;
    
    location / {
        proxy_pass http://guacamole:8080/guacamole/;
    }
}
ENDCONFIG_SSL

  else

    cat <<ENDCONFIG_NOSSL > volumes/nginx/etc/nginx/conf.d/default.conf
server {
    listen      80;
    listen [::]:80;

    server_name   $DOMAIN_NAME;
    server_tokens off;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        proxy_pass http://guacamole:8080/guacamole/;
    }
}
ENDCONFIG_NOSSL

  fi
  
fi

# Edit docker-compose.yml.

echo "Adjusting docker-compose.yml."

tmp=$(mktemp)
trap "rm -f '$tmp'" EXIT

if [ -n "$HTTPS_PORT" ]; then
  cat docker-compose.yml | sed -re 's/^[[:space:]]*#[[:space:]]*\-[[:space:]]*\$\{HTTPS_PORT\}:443$/      - ${HTTPS_PORT}:443/' > "$tmp"
else
  cat docker-compose.yml | sed -re 's/^[[:space:]]*\-[[:space:]]*\$\{HTTPS_PORT\}:443$/      #- ${HTTPS_PORT}:443/' > "$tmp"
fi

cat "$tmp" > docker-compose.yml
