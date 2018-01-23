FROM mariadb:10.1

LABEL Description="This image is used to start mariadb" Vendor="Museum für Naturkunde Berlin" Version="0.2"

#########################
#
# Docker instructions
#
#########################

# Webserver port
EXPOSE 3306

# mountpoint for database
VOLUME /var/lib/mysql
RUN chown -R mysql:mysql /var/lib/mysql

# Custom settings
COPY mariadb.cnf /etc/mysql/conf.d/

   
