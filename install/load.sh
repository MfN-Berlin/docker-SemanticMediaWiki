#! /bin/bash

# Run this script on the test server to:
#
# 1. Load previosly built docker containers on the test server.
# 2. Import a database dump and media exported from another wiki.
#
# The wiki database is on docker volume ikondb (on the host)
# The upload directory is in /local/docker/test-ikon/ikon-smw-stack/data/upload/media (on the host)
#

# Read configuration options
source config.ini

configure() {
	# read database root password from input, if not set in config.ini
	if [ -z ${MYSQL_ROOT_PASSWORD+x} ]; then read -s -p "Password for database root: " MYSQL_ROOT_PASSWORD; fi
	echo "";
	
	# read database password from input, if not set in config.ini
	if [ -z ${MYSQL_PASSWORD+x} ]; then read -s -p "Password for database user $MYSQL_USER: " MYSQL_PASSWORD; fi
	echo "";
		
	# read mediawiki database name from input, if not set in config.ini
	if [ -z ${MYSQL_DATABASE+x} ]; then read -p "Name of the database used by this mediawiki: " MYSQL_DATABASE; fi
	echo "";

	export SMW_CONTAINER
	export DB_CONTAINER
	export UPLOAD_MOUNT
	export DB_MOUNT
	export NETWORK
	export MYSQL_ROOT_PASSWORD
	export MYSQL_USER
	export MYSQL_PASSWORD
	export MYSQL_DATABASE
	export PORT
	export PORTDB
	export MW_DOCKERDIR
}

# Remove old docker images and volumes,
# create a new volume for the database,
# load new docker images for the wiki and the database
# start the wiki and the database.
#
# You may need to restart the proxy after the script has finished:
#  pound -c
#  sudo systemctl restart pound
load() {
    # Stop and remove old containers
    sudo docker stop $SMW_CONTAINER
    sudo docker rm $SMW_CONTAINER
    sudo docker stop $DB_CONTAINER
    sudo docker rm $DB_CONTAINER
    # remove old database volume
    # sudo docker volume rm ikondb

    # create database volume
    # sudo docker volume create ikondb

    ## create a network
    sudo docker network create --driver bridge $NETWORK
    
    # load images in docker
    echo "Loading images in docker"
    sudo docker load -i $DB_CONTAINER.tar
    sudo docker load -i $SMW_CONTAINER.tar    
}

configure
load
