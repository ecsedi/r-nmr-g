#!/bin/bash

set -e

# Check existence of commands.

ok="yes"

for cmd in dirname realpath docker mktemp egrep sed tr date wc; do
  if ( which "$cmd" > /dev/null 2>&1 ); then
    :
  else
    echo "$cmd not found in the PATH"
    ok="no"
  fi
done

if [ "$ok" != "yes" ]; then
  exit 1
fi

cd $(dirname $(realpath "$0"))

for image in "nginx:latest" "certbot/certbot" "guacamole/guacamole" "guacamole/guacd" "mariadb:10.7.3"; do
  docker pull "$image"
done

./init-volumes.sh

. .env

echo ""
echo "Containers and volumes are ready. To start, enter:"
echo "docker compose up -d"
echo ""

if [ -n "$HTTPS_PORT" ]; then

  certdir="volumes/certbot/etc/letsencrypt/live/$DOMAIN_NAME"

  if [ -z "$(ls -A "$certdir" 2> /dev/null)" ]; then
    echo "Before starting guacamole, please create SSL key and certificate pair for the site."
    echo "Either execute ./create-cert.sh for a Let's Encrypt certificate"
    echo "or place your existing certificate+chain and key files into:"
    echo "- $certdir/fullchain.pem"
    echo "- $certdir/privkey.pem"
    echo "as nginx will look for them under these names."
    echo ""
  fi

fi
