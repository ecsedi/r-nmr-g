create database guacamole default character set utf8 default collate utf8_unicode_ci;
create user 'guacamole'@'%' identified by 'GUACAMOLE_DB_PASSWORD';
grant all on guacamole.* to 'guacamole'@'%';
