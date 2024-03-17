# r-nmr-g

Remote NMR guacamole docker suite
================================

This guacamole installation uses the following docker images:

- guacamole/guacamole
- guacamole/guacd
- mariadb:10.7.3
- nginx:latest
- certbot/certbot:latest

The guacamole container can only handle HTTP. In a production environment
SSL/TLS is required which is achieved by using an nginx reverse proxy.

User and connection details are stored in a mariadb database.

If getting a commercial certificate is difficult then there is a certbot
container and some simple tools included for generating and renewing a Let's
Encrypt certificate for the site.

Setting up a new guacamole installation
---------------------------------------

1. Copy `.env.sample` to `.env`. Edit `.env` and set the variables in it.
   Choose a domain name for the site, set port numbers, passwords and an email
   address to be used with certbot.
   The `HTTPS_PORT` variable can be removed if no SSL is needed, although it is
   recommended only for testing purposes.
2. Execute `01-setup.sh` to initialize guacamole's database, nginx and docker
   configuration.
3. Create an SSL certificate for the site if needed either with the
   `create-cert.sh` script or manually copying the certificate and key files to
   their folders (the exact locations are displayed by the `01-setup.sh` script).
   **NOTE:** certbot can only operate on port 80 of the host so it must not be
   occupied by something else.
4. Start the containers by executing `docker compose up -d`.
5. Direct your browser to the site and log in as the default guacamole admin
   `guacadmin` using the default password `guacadmin`.
6. Add a new admin user, log out, log in with the new user and remove the old
   admin account.
7. Set up regular users and connections. Assign connections to your users.

Environment variables
---------------------

The environment file `.env` contains the following variables:

- MARIADB_ROOT_PASSWORD: root password of the MariaDB database
- GUACAMOLE_DB_PASSWORD: password for the guacamole database
- HTTP_PORT: connect this port of the host to the HTTP port of the nginx container
- HTTPS_PORT: connect this port of the host to the HTTPS port of the nginx container
- DOMAIN_NAME: the official domain name of the guacamole server (FQDN)
- CERTBOT_EMAIL: email address to use with certbot registration

Cleaning up
-----------

To clean up after a previous setup and start a fresh guacamole installation
execute `clean-volumes.sh`. It will remove the database, the nginx configuration
and the SSL certificate/key pair. **NOTE:** guacamole must be stopped before
cleaning up.

Starting guacamole
------------------

Execute `docker compose up -d` and connect to the site with a browser. Site name
and port number can be obtained from the `.env` file.

Stopping guacamole
------------------

Execute `docker compose down`.

Certificate management with certbot
-----------------------------------

Before using certbot set the domain name (`DOMAIN_NAME`) and email address
(`CERTBOT_EMAIL`) in `.env`.

Certbot scripts use port 80 of the host so make sure that no other program
listens on it when you execute them. By default nginx binds to port 80.
Stop guacamole first with `docker compose down`.

Create a certificate with `create-cert.sh` and renew it with `renew-cert.sh`.

In case you need to do other tasks there is a generic `certbot.sh` script.

First steps
-----------

1. Log in with the default username/password: `guacadmin/guacadmin`.
2. Change the default password or better, create a new admin account, log in
   with it and delete the original admin user.
3. Create regular users.
4. Set up connections.
5. Assign connections to users.

Network related considerations
==============================

Usually the guacamole server is inside an institutional network behind a
firewall. If you use the default port numbers then only TCP port 80 and 443 need
to be allowed through the firewall.

Internal NMR servers might further defend themselves with their own firewall
rules so it is important to allow at least some traffic coming from the
guacamole server. In the case of a Windows server it means the RDP port
(TCP/3389). In the case of a Linux server SSH (TCP/22) and some VNC connections
(somewhere between TCP/5900-5910 - depends on your setup) are recommended.

Managing guacamole connections
==============================

