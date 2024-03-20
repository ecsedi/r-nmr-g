r-nmr-g - The remote NMR guacamole docker suite
===============================================

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

Connecting to a Windows controlling station
-------------------------------------------

In order to access a Windows desktop an RDP connection must be made. In the
simplest case you need to specify only the IP or domain name of the Windows
station and enable the connection for your guacamole users.

Log in as the guacamole administrator and create a new connection:

            Edit Connection
               Name:     Windows NMR Controlling Station
               Location: ROOT
               Protocol: RDP
            Parameters
               Network
                  Hostname: nmr-station.example.com
                  Port:

With this minimal setup you users must enter the username and password when they
want to connect to the controlling station. If this is not desired then you have
the option to specify a username/password pair in the `Authentication` section
of the connection configuration. In this way regular users will not have access
to the password but they will still be able to connect to the controlling station.

TODO: File access during the RDP connection is possible. Provide details.

Connecting to a Linux controlling station
-----------------------------------------

VNC is the preferred method of connecting to a Linux station. Users log in to an
X-Windows session when they are working locally. To provide remote access you
can pick one of two different approaches. Either you can log in locally to the
console and share that X session through a VNC connection using `x11vnc` or you
can create a virtual X server using `vncserver`.

### Single user sharing a local X session

In this scenario a signle VNC connection can be shared by any number of
guacamole users. To prevent multiple parallel sessions to the controlling
station, the number of concurrent connections can be limited to 1.

This solution is similar to a Windows RDP connection, although not too flexible
since everybody uses the same Linux account and the advantages of native Linux
user separation are lost. When users must be better separated from each other
then this is not the way to follow, although in a very small scale it is a
viable, easy to set up option.

**Steps:**

1. Start an X-Windows session on the controlling station.
2. Open a terminal and execute **`x11vnc -usepw -forever -nevershared`**
   command. This will attach a VNC server to the current X display and will keep
   accepting connections until killed.
   At first execution it asks for a password and creates a password file
   (`$HOME/.vnc/passwd`). Subsequent invocations will use the existing password
   file. To set up a new password `$HOME/.vnc/passwd` must be deleted before
   starting `x11vnc`.
3. Create a VNC connection in guacamole. Edit the connection and
   - Under `Concurrency Limits` set `Maximum number of connections` to **1**.
   - Under `Parameters` - `Network` fill in `Hostname` (of the controlling
     station) and `Port` (5900).
   - Under `Parameters` - `Authentication` set the VNC password (entered in the
     previous step).
   - If you want to provide file access during the VNC session, you should
     enable SFTP under `Parameters` - `SFTP` by checking `Enable SFTP` and
     filling in `Hostname` (of the controlling station), `Username` (who started
     `x11vnc` on the controlling station) and `Password` (of the said user).
4. Assign this connection to your guacamole users.

**Advantages:** Users need only one username/password pair to log in to the
guacamole server. Once logged in they simply click on the connection and it just
works. File transfer is also available during the VNC session (only with SFTP
enabled).

**Disadvantages:** No user separation on the controlling station. This can only
work with a small user base where members trust each other.

**Important:** Make sure that the firewall rules on the controlling station
allow TCP connections from the guacamole server at least on port 5900 (VNC) and
on port 22 (SFTP).

### Per user VNC connections

In this scenario every guacamole user has a separate account on the controlling
station. However this requires a different approach for starting the VNC server
and ensuring mutual exclusion of users connecting at the same time.

Users now have to start their own VNC server on the controlling station prior to
opening a guacamole VNC conection and they are required to terminate the VNC
server as soon as they finish their experiment. This can be achieved with two
guacamole connections: an SSH connection to start the VNC server and a VNC
connection to do the experiment.

Because there is a good chance that X display :0 is already occupied on the
controlling station, a different display number must be used. Usually display :1
is free. The VNC port number changes with the display number: VNC connections to
:0 use port 5900, to :1 they use 5901 and so on. Pay attention to this when
setting firewall rules on the controlling station!

Every user must use the same display number when starting the VNC server. This
ensures mutual exclusion because if a VNC server is already running then another
one cannot be started with the same display number.

**The protocol users must follow:**

1. Log in to the guacamole server.
2. Open an SSH connection to the controlling station and log in with the Linux
   username/password pair.
3. Execute **`vncserver -geometry 1600x900 :1`** (any geometry is OK, it can
   be omitted as well, but the default screen size is usually too small). At
   first execution it will ask for a password for the VNC connection. The same
   password will be used in subsequent sessions. If a new password is required
   then `$HOME/.vnc/passwd` must be removed before starting `vncserver`.
4. When the VNC server is running the SSH session can be closed.
5. Open a VNC connection in guacamole and specify the VNC session password.
6. When the experiment is finished open a terminal in the VNC session and
   execute **`vncserver -kill :1`** and the session will be disconnected as the
   X server exits.

The VNC server can be killed from an SSH connection, too.

In this configuration file transfer is enabled in the SSH connection, not in the
VNC connection (as it was in the previous scenario).

In guacamole 2 connections must be created: an SSH and a VNC connection.

**Guacamole connection setup:**

1. Create an SSH connection.
   - Under `Parameters` - `Network` fill in `Hostname` (of the controlling
   station). No username or password is needed. Users will be asked when they
   open the connection.
   - Optionally enable SFTP under `Parameters` - `SFTP` by checking `Enable SFTP`.
   There is no login name here for the SSH login user will be used.
2. Create a VNC connection.
   - Under `Parameters` - `Network` fill in `Hostname` (of the controlling
   station) and `Port` (5901 if using display :1).
3. Assign these two connections to guacamole users.

**Advantages:** Users are properly separated. Access to other users' files can
be restricted. Everyone can enjoy a customized graphical user interface. Users
can set their own VNC session password.

**Disadvantages:** Users have to remember more credentials (one guacamole
username/password pair, one Linux username/password pair and a VNC session
password - in fact these can be reduced to a single guacamole username/password
pair when per-user SSH and VNC connections are configured and SSH keys are used,
but it is beyond the limits of this simple tutorial). It is also a problem when
a user forgets to kill his VNC server thus preventing others from starting their
own but it can be handled with the intervention of the Linux administrator.

**Important:** Make sure that the firewall rules on the controlling station
allow TCP connections from the guacamole server at least on port 22 (SSH) and
port 5901 (VNC). If the display number is different from :1 then the VNC port
must be modified accordingly.

**Important:** For this solution to work SSH password authentication must be
enabled on the controlling station. The SSH server can be configured to allow
this only for connections from the guacamole server so it won't create a
significant security issue.
