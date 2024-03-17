#!/bin/bash

set -e

cd /volumes/init

cat mysql-db.sql | sed -re "s/GUACAMOLE_DB_PASSWORD/$2/" | mysql --user=root --password="$1"
cat mysql-schema.sql | mysql --user=root --password="$1" guacamole
