#!/bin/bash

set -e

cd $(dirname $(realpath "$0"))

. .env

docker run \
  -it --rm \
  -p "80:80" \
  -v $(pwd)/volumes/certbot/var/www/certbot/:/var/www/certbot/:rw \
  -v $(pwd)/volumes/certbot/etc/letsencrypt/:/etc/letsencrypt/:rw \
  certbot/certbot:latest "$@"
