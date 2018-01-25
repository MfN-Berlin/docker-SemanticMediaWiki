#! /bin/bash

# Create a docker container with a MediaWiki installation
# Create a docker container with a MariaDB installation
#
# @author Alvaro Ortiz for Museum fuer Naturkunde, 2017
# contact: alvaro.OrtizTroncoso@mfn-berlin.de

echo "Please choose:"
echo "1. Build new Docker containers"
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

##############################
#
# Build the database container
#
##############################
build_db() {
    docker build \
	   -f $HOST_FILES/mariadb/dockerfile \
	   -t $DB_CONTAINER $HOST_FILES/mariadb

    # Run on the default network during image creation
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

##############################
#
# Build the wiki container
# Create the network.
#
##############################
build_smw() {
    cd $HOST_FILES/smw
    
    # Prepare Localsettings from template
    cp LocalSettings.tpl.php LocalSettings.php
    sed -i "s|@@ScriptPath@@|$MW_SCRIPTPATH|g" LocalSettings.php
    sed -i "s|@@WikiName@@|$MW_WIKINAME|g" LocalSettings.php
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
    cd ../../

    # Copy the skin to the container context 
    mkdir -p $HOST_FILES/smw/skins
    cp -r $MW_SKIN $HOST_FILES/smw/skins
    # Copy the logo to the container context
    cp $MW_SKIN/Logo.png $HOST_FILES/smw
    
    ## Use the IP address from the default network during installation.
    MARIADB_HOST=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' $DB_CONTAINER`
    CACHE_INSTALL=`date +%Y-%m-%d-%H-%M`
    
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

    # Run on the default network during image creation
    docker run --name $SMW_CONTAINER \
    -p $PORT:80 \
    -v $UPLOAD_MOUNT:$MW_DOCKERDIR/images \
    -d \
    $SMW_CONTAINER

    ## Stop the containers, as they need to be restarted using the custom network.
    stop

    ## create a network
    docker network create --driver bridge $NETWORK

    # cleanup
    rm $HOST_FILES/smw/LocalSettings.php
    rm -r $HOST_FILES/smw/skins
}

####################################
#
# Start the wiki and db containers.
#
####################################
start() {
    # start the db container
    docker rm $DB_CONTAINER
    docker run \
	   --restart always \
	   --name $DB_CONTAINER \
	   --network=$NETWORK \
	   -v $DB_MOUNT:/var/lib/mysql \
	   -d \
	   $DB_CONTAINER

    # start the mediawiki container
    docker rm $SMW_CONTAINER
    docker run \
	   --restart always \
	   --name $SMW_CONTAINER \
	   --network=$NETWORK \
	   -p $PORT:80 \
	   -v $UPLOAD_MOUNT:$MW_DOCKERDIR/images \
	   -d \
	   $SMW_CONTAINER

    ## Change the address of the database in wiki LocalSettings to the name of the mariadb container in the newly created network.
    docker exec -ti $SMW_CONTAINER script -q -c "sed -i 's|\$wgDBserver = \(.*\);|\$wgDBserver = \"$DB_CONTAINER\";|g' $MW_DOCKERDIR/LocalSettings.php"

    echo "Access wiki at: http://localhost:$PORT/wiki"
}

###################################
#
# Stop the wiki and db containers.
#
###################################
stop() {
    # stop all containers
    docker stop $SMW_CONTAINER
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
        build_db
	build_smw
	start
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
    *)
        echo "Unbekannte Option"
        ;;
esac
