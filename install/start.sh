#! /bin/bash

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

start() {
    # Start docker container
    bash $HOST_FILES/ikon_smw_test.sh
}

configure
start
