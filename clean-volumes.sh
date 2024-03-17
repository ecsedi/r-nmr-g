#!/bin/bash

set -e

MARIADB_IMAGE='mariadb:10.7.3'

cd $(dirname $(realpath "$0"))

. .env

function yes_or_no() {
  answer=$(echo "$1" | tr 'A-Z' 'a-z')
  if [ "$answer" = "yes" -o "$answer" = "y" ]; then
    echo "yes"
  else
    if [ "$answer" = "no" -o "$answer" = "n" ]; then
      echo "no"
    else
      echo "unknown"
    fi
  fi
}

if [ -n "$(ls -A volumes/guadb/var/lib/mysql/)" ]; then
  echo "Found existing guacamole database in volumes/guadb/var/lib/mysql."
  echo -n "Do you want to remove it completely (yes/[NO])? "
  read answer
  answer=$(yes_or_no "$answer")
  if [ "$answer" = "yes" ]; then
    echo "Removing previous guacamole database."
    now=$(date '+%Y%m%d%H%M%S')
    mariadb_container="guadb_clean_$now"
    docker run                                                   \
      --name "$mariadb_container"                                \
      --rm                                                       \
      -it                                                        \
      -v "$(pwd)/volumes/guadb/var/lib/mysql/":"/var/lib/mysql/" \
      -v "$(pwd)/volumes/init/":"/volumes/init/"                 \
      "$MARIADB_IMAGE" /volumes/init/mysql-clean-db.sh
  else
    echo "Keeping previous guacamole database."
  fi
else
  echo "No previous guacamole database found."
fi

if [ -f volumes/nginx/etc/nginx/conf.d/default.conf ]; then
  echo "Found existing nginx configuration in volumes/nginx/etc/nginx/conf.d/default.conf."
  echo -n "Do you want to remove it completely (yes/[NO])? "
  read answer
  answer=$(yes_or_no "$answer")
  if [ "$answer" = "yes" ]; then
    echo "Removing previous nginx configuration."
    rm -f volumes/nginx/etc/nginx/conf.d/default.conf
  else
    echo "Keeping previous nginx configuration."
  fi
else
  echo "No previous nginx configuration found."
fi

certdir="volumes/certbot/etc/letsencrypt/live/$DOMAIN_NAME"
archdir="volumes/certbot/etc/letsencrypt/archive/$DOMAIN_NAME"
cbotcfg="volumes/certbot/etc/letsencrypt/renewal/$DOMAIN_NAME.conf"

if [ -d "$certdir" ]; then
  if [ -n "$(ls -A "$certdir")" ]; then
    echo "Existing site certificate detected in $certdir"
    echo -n "Do you want to remove it (yes/[NO])? "
    read answer
    answer=$(yes_or_no "$answer")
    if [ "$answer" = "yes" ]; then
      echo "Removing site certificate."
      rm -rf "$certdir"
      rm -rf "$archdir"
      rm -f  "$cbotcfg"
    else
      echo "Keeping site certificate."
    fi
  fi
else
  echo "No existing certificate found."
fi
