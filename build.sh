#! /bin/bash

# Create a docker container with a MediaWiki installation
# Create a docker container with a MariaDB installation
#
# @author Alvaro Ortiz for Museum fuer Naturkunde, 2017
# contact: alvaro.OrtizTroncoso@mfn-berlin.de

echo "Please choose:"
echo "1. Build new Docker containers (run as root)"
echo "2. Start Docker containers"
echo "3. Stop Docker containers"
echo "13: Kill all images and volumes (run as root)"
echo "0. Usage"
read -p "? " opt

# Read configuration options
source config.ini

usage() {
    # Show usage information
    echo "See README."
}

##########################################
#
# Build all the containers
# Create the network.
# (db container has to be created first).
#
##########################################
build() {
    build_db
    build_parsoid
    build_smw
    post_build
}

###########################################
#
# Build the db, Parsoid an wiki containers
#
###########################################
build_db() {
    docker build \
	   -f $HOST_FILES/mariadb/dockerfile \
	   -t $DB_CONTAINER $HOST_FILES/mariadb

    # Run on the default network ("bridge") during image creation
    docker run --name $DB_CONTAINER \
	   -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
	   -e MYSQL_DATABASE=$MYSQL_DATABASE \
	   -e MYSQL_USER=$MYSQL_USER \
	   -e MYSQL_PASSWORD=$MYSQL_PASSWORD \
	   -v $DB_MOUNT:/var/lib/mysql \
	   -p $PORTDB:3306 \
	   -d \
	   $DB_CONTAINER
}

build_parsoid() {
    ## Create config.yaml    
    cd $HOST_FILES/parsoid
    cp config.tpl.yaml config.yaml
    sed -i "s|@@SMW_CONTAINER@@|$SMW_CONTAINER|g" config.yaml
    cd ../../
    
    docker build \
    -f $HOST_FILES/parsoid/dockerfile \
    -t $PARSOID_CONTAINER $HOST_FILES/parsoid
}

build_smw() {

    ## Use the IP address from the default network during installation.
    MARIADB_HOST=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' $DB_CONTAINER`
    CACHE_INSTALL=`date +%Y-%m-%d-%H-%M`
    
    ## Create LocalSettings.php
    cd $HOST_FILES/smw
    cp LocalSettings.tpl.php LocalSettings.php
    sed -i "s|@@ScriptPath@@|$MW_SCRIPTPATH|g" LocalSettings.php
    sed -i "s|@@WikiName@@|$MW_WIKINAME|g" LocalSettings.php
    sed -i "s|@@dbServer@@|$MARIADB_HOST|g" LocalSettings.php
    sed -i "s|@@database@@|$MYSQL_DATABASE|g" LocalSettings.php
    sed -i "s|@@dbUser@@|$MYSQL_USER|g" LocalSettings.php
    sed -i "s|@@dbPass@@|$MYSQL_PASSWORD|g" LocalSettings.php
    sed -i "s|@@dbprefix@@|$MYSQL_PREFIX|g" LocalSettings.php
    sed -i "s|@@Email@@|$MW_EMAIL|g" LocalSettings.php
    sed -i "s|@@Logo@@|"$MW_SCRIPTPATH/$MW_LOGO"|g" LocalSettings.php
    sed -i "s|@@bgImage@@|"$MW_SCRIPTPATH/$MW_BG"|g" LocalSettings.php
    sed -i "s|@@bgColor@@|$MW_BGCOL|g" LocalSettings.php
    sed -i "s|@@skin@@|$MW_SKIN|g" LocalSettings.php
    sed -i "s|@@skintpl@@|$MW_SKINTPL|g" LocalSettings.php
    sed -i "s|@@smwContainer@@|$SMW_CONTAINER|g" LocalSettings.php
    sed -i "s|@@parsoidContainer@@|$PARSOID_CONTAINER|g" LocalSettings.php
    sed -i "s|@@network@@|$NETWORK|g" LocalSettings.php
    cd ../../

    # Copy the skin to the container context 
    mkdir -p $HOST_FILES/smw/skins
    cp -r $MW_SKIN $HOST_FILES/smw/skins
    # Copy the logo to the container context
    cp $MW_SKIN/Logo.png $HOST_FILES/smw

    docker build \
    --build-arg UPLOAD_MOUNT=$UPLOAD_MOUNT \
    --build-arg MW_EMAIL=$MW_EMAIL \
    --build-arg MEDIAWIKI_VERSION=$MEDIAWIKI_VERSION \
    --build-arg MEDIAWIKI_FULL_VERSION=$MEDIAWIKI_FULL_VERSION \
    --build-arg MYSQL_DATABASE=$MYSQL_DATABASE \
    --build-arg MYSQL_USER=$MYSQL_USER \
    --build-arg MYSQL_PASSWORD=$MYSQL_PASSWORD \
    --build-arg MYSQL_HOST=$MARIADB_HOST \
    --build-arg MYSQL_PREFIX=$MYSQL_PREFIX \
    --build-arg MW_PASSWORD=$MW_PASSWORD \
    --build-arg MW_SCRIPTPATH=$MW_SCRIPTPATH \
    --build-arg MW_DOCKERDIR=$MW_DOCKERDIR \
    --build-arg MW_WIKINAME=$MW_WIKINAME \
    --build-arg MW_WIKIUSER=$MW_WIKIUSER \
    --build-arg CACHE_INSTALL=$CACHE_INSTALL \
    --build-arg MW_SKIN=$MW_SKIN \
    --build-arg UserFunctions_DOWNLOAD_URL=$UserFunctions_DOWNLOAD_URL \
    --build-arg HeaderTabs_DOWNLOAD_URL=$HeaderTabs_DOWNLOAD_URL \
    --build-arg WikiCategoryTagCloud_DOWNLOAD_URL=$WikiCategoryTagCloud_DOWNLOAD_URL \
    --build-arg SimpleChanges_DOWNLOAD_URL=$SimpleChanges_DOWNLOAD_URL \
    --build-arg Lockdown_DOWNLOAD_URL=$Lockdown_DOWNLOAD_URL \
    --build-arg PDFEmbed_DOWNLOAD_URL=$PDFEmbed_DOWNLOAD_URL \
    --build-arg LDAP_DOWNLOAD_URL=$LDAP_DOWNLOAD_URL \
    --build-arg VisualEditor_DOWNLOAD_URL=$VisualEditor_DOWNLOAD_URL \
    --build-arg ParserFunctions_DOWNLOAD_URL=$ParserFunctions_DOWNLOAD_URL \
    --build-arg CategoryTree_DOWNLOAD_URL=$CategoryTree_DOWNLOAD_URL \
    --build-arg WikiEditor_DOWNLOAD_URL=$WikiEditor_DOWNLOAD_URL \
    -f $HOST_FILES/smw/dockerfile \
    -t $SMW_CONTAINER $HOST_FILES/smw/

    # cleanup
    rm -r $HOST_FILES/smw/skins
}

#####################################
#
# Create the network.
# Update network settings
# Restart
#
#####################################
post_build() {
    ## Stop the containers, as they need to be restarted using the custom network.
    stop
    ## create a network
    docker network create --driver bridge $NETWORK
    ## Create the mount point for configuration files
    mkdir -p $CONFIG_MOUNT
    ## Copy the LocalSettings file to the mount point for configuration files
    mv  $HOST_FILES/smw/LocalSettings.php $CONFIG_MOUNT
    ## Change the address of the database in wiki LocalSettings to the name of the mariadb container in the custom created network.
    sed -i "s|\$wgDBserver = \(.*\);|\$wgDBserver = \"$DB_CONTAINER\";|g" $CONFIG_MOUNT/LocalSettings.php
    ## Copy the Parsoid configuration file to the mount point for configuration files
    mv $HOST_FILES/parsoid/config.yaml $CONFIG_MOUNT
}

#############################################
#
# Start the wiki, Parsoid and db containers.
#
#############################################
start() {
    # start the db container
    docker rm $DB_CONTAINER
    run_db

    # start the Parsoid container
    docker rm $PARSOID_CONTAINER
    run_parsoid
    
    # start the mediawiki container
    docker rm $SMW_CONTAINER
    run_smw

    # feedback
    docker ps | grep $PROJECT
    echo "Access wiki at: http://localhost:$PORT/wiki"
}

run_db() {
    docker run \
	   --restart always \
	   --name $DB_CONTAINER \
	   --network=$NETWORK \
	   -v $DB_MOUNT:/var/lib/mysql \
	   -d \
	   $DB_CONTAINER
}

run_parsoid() {
    docker run \
	   --restart always \
	   --name $PARSOID_CONTAINER \
	   --network=$NETWORK \
	   -p $PORTPARSOID:8000 \
	   -v $CONFIG_MOUNT/:/data \
	   -d \
	   $PARSOID_CONTAINER
}

#run_parsoid() {
    # start the mediawiki container
#    docker rm $PARSOID_CONTAINER
#    docker run \
#	   --name $PARSOID_CONTAINER \
#	   --network=$NETWORK \
#	   -p $PORTPARSOID:8142 \
#	   -v $CONFIG_MOUNT/parsoid_config.yaml:/usr/lib/parsoid/src/config.yaml \
#	   -d \
#	   $PARSOID_CONTAINER
#}

run_smw() {
    docker run \
	   --restart always \
	   --name $SMW_CONTAINER \
	   --network=$NETWORK \
	   -p $PORT:80 \
	   -v $UPLOAD_MOUNT:$MW_DOCKERDIR/images \
	   -v $CONFIG_MOUNT/LocalSettings.php:$MW_DOCKERDIR/LocalSettings.php  \
	   -d \
	   $SMW_CONTAINER
}

#############################################
#
# Stop the wiki, Parsoid and db containers.
#
#############################################
stop() {
    # stop all containers
    docker stop $SMW_CONTAINER
    docker stop $PARSOID_CONTAINER
    docker stop $DB_CONTAINER
}


#########################################
#
# Cleanup everything
# (all images of all projects),
# the hard way.
#
# * remove all containers and images
# * delete docker files directly
# * delete all saved data on the host
#
#########################################
killallimages() {
    # remove all containers and images
    docker rm -f $(docker ps -a -q) && docker rmi -f $(docker images -q) && docker rmi -f $(docker images -a -q)
    docker network rm $NETWORK
    service docker stop
    # delete docker files directly
    rm -rf /var/lib/docker/aufs
    rm -rf /var/lib/docker/image/aufs
    rm -f /var/lib/docker/linkgraph.db
    rm -rf /var/lib/docker/volumes
    # delete all saved data on the host
    rm -rf $UPLOAD_MOUNT
    rm -rf $DB_MOUNT
    rm -rf $CONFIG_MOUNT
    # restart service
    service docker start
    # show partition usage
    df -h
}

case $opt in 
    0)
        usage
        ;;
    1)
        build
        ;;
    2)
        start
        ;;
    3)
        stop
        ;;
    13)
        killallimages
        ;;
    20)
	build_parsoid
	;;
    21)
	run_parsoid
	;;
    *)
        echo "Unbekannte Option"
        ;;
esac
