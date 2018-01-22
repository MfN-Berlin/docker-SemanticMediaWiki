#! /bin/bash

#
# Create a docker container with a MediaWiki installation
# Create a docker container with a MariaDB installation
#
# @author Alvaro Ortiz for Museum fuer Naturkunde, 2017
# contact: alvaro.OrtizTroncoso@mfn-berlin.de
#
echo "Specify a configuration file or else only config.ini will be used."
echo "Please choose:"
echo "1. Setup new Docker Container"
echo "2. Start Docker Container (local)"
echo "3. Stop Docker Container"
echo "4. Import from another wiki"
echo "5. Import a database dump and media directory, create sysop"
echo "6. Pack and deploy on test server"
echo "7. Dump database for import"
echo "13: Kill all images and volumes (use when the hard disk is full)"
echo "0. Usage"
read -p "? " opt

# Read configuration options
source config.ini
# NOTE: this will export db and wiki passwords to environment of
# the (local) machine where the wimages are build.
export SMW_CONTAINER
export DB_CONTAINER
export NETWORK
export UPLOAD_MOUNT
export DB_MOUNT
export LOG_MOUNT
export MEDIAWIKI_VERSION
export MEDIAWIKI_FULL_VERSION
export DOMAIN_NAME
export MYSQL_ROOT_PASSWORD
export MYSQL_DATABASE
export MYSQL_USER
export MYSQL_PASSWORD
export MYSQL_PREFIX
export MYSQL_DUMP
export MEDIA
export MW_PASSWORD
export MW_SCRIPTPATH
export MW_DOCKERDIR
export MW_WIKINAME
export MW_WIKIUSER
export MW_EMAIL
export PORT
export PORTDB
export MW_LOGO
export MW_BG
export MW_BGCOL
export MW_SKIN
export MW_SKINTPL
export UserFunctions_DOWNLOAD_URL
export HeaderTabs_DOWNLOAD_URL
export WikiCategoryTagCloud_DOWNLOAD_URL
export SimpleChanges_DOWNLOAD_URL
export Lockdown_DOWNLOAD_URL
export PDFEmbed_DOWNLOAD_URL
export LDAP_DOWNLOAD_URL
export VisualEditor_DOWNLOAD_URL
export ParserFunctions_DOWNLOAD_URL
export CategoryTree_DOWNLOAD_URL
export WikiEditor_DOWNLOAD_URL

usage() {
    # Show usage information
    echo "See README."
}

build() {
    cd $HOST_FILES    
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
    
    # Create docker image
    ./ikon_smw.sh
}

import() {
    # read name of database dump file to import from input, if not set in config.ini
    if [ -z ${MYSQL_DUMP+x} ]; then read -p "Name of the database dump file to import: " MYSQL_DUMP; fi
    echo "";
    export MYSQL_DUMP
    
    # read name of media directory to import from input, if not set in config.ini
    if [ -z ${MEDIA+x} ]; then read -p "Media directory to import: " MEDIA; fi
    echo "";    
    export MEDIA

    # import database dump
    echo "Loading database dump"
    sudo docker cp $MYSQL_DUMP $DB_CONTAINER:dump.sql
    # sudo docker exec -ti $DB_CONTAINER script -q -c "mysqladmin -u root -p$MYSQL_ROOT_PASSWORD create $MYSQL_DATABASE"
    sudo docker exec -ti $DB_CONTAINER script -q -c "mysql -uroot -p$MYSQL_ROOT_PASSWORD $MYSQL_DATABASE < dump.sql"
    sudo docker exec -ti $DB_CONTAINER script -q -c "grant all privileges on mfn_fp.* to 'mediawiki'@'%';"

    # import media
    docker cp $MEDIA $SMW_CONTAINER:$MW_DOCKERDIR/media2
    docker exec -ti $SMW_CONTAINER script -q -c "cp -r $MW_DOCKERDIR/media2/* $MW_DOCKERDIR/images/"
    docker exec -ti $SMW_CONTAINER script -q -c "chown -R www-data:www-data $MW_DOCKERDIR/images/"
    
    # cleanup
    docker exec -ti $SMW_CONTAINER script -q -c "cd $MW_DOCKERDIR && rm -r media2"
    docker exec -ti $DB_CONTAINER script -q -c "rm dump.sql"
    rm LocalSettings.php
}

createSysop() {
    docker exec -ti $SMW_CONTAINER script -q -c "php $MW_DOCKERDIR/maintenance/createAndPromote.php --force --bureaucrat --sysop $MW_WIKIUSER $MW_PASSWORD"
}

start() {
    ## create a network
    docker network create --driver bridge $NETWORK
    
    # Start docker container
    $HOST_FILES/ikon_smw_start.sh
}

stop() {
    # stop all containers
    docker stop $(docker ps -a -q)
}

importwiki() {
    # Import from another wiki
    php ./importFp/migrateWiki.php
    # rebuild the wiki database after import
    docker exec -it $SMW_CONTAINER php $MW_DOCKERDIR/maintenance/rebuildall.php
}

deploy_test() {
    # read username to connnect to the testserver username from input, if not set in config.ini
    if [ -z ${TEST_USERNAME+x} ]; then read -p "Username for testserver $TEST_USERNAME: " TEST_USERNAME; fi
    echo "";
        
    # pack images
    echo "packing /tmp/$DB_CONTAINER.tar"
    docker save -o /tmp/$DB_CONTAINER.tar $DB_CONTAINER
    echo "packing /tmp/$SMW_CONTAINER.tar"
    docker save -o /tmp/$SMW_CONTAINER.tar $SMW_CONTAINER

    # upload docker images
    echo "connecting to $TEST_USERNAME@$TEST_SERVER_IP"
    ssh $TEST_USERNAME@$TEST_SERVER_IP "mkdir -p $TEST_SERVER_PATH"
    scp /tmp/$DB_CONTAINER.tar $TEST_USERNAME@$TEST_SERVER_IP:$TEST_SERVER_PATH
    scp /tmp/$SMW_CONTAINER.tar $TEST_USERNAME@$TEST_SERVER_IP:$TEST_SERVER_PATH
    
    # dump database
    dump_db
    
    # upload database dump
    echo "connecting to $TEST_USERNAME@$TEST_SERVER_IP"
    scp /tmp/dump.sql $TEST_USERNAME@$TEST_SERVER_IP:$TEST_SERVER_PATH

    # dump media dir
    dump_media

    # upload media dir
    echo "connecting to $TEST_USERNAME@$TEST_SERVER_IP"
    scp -r /tmp/images $TEST_USERNAME@$TEST_SERVER_IP:$TEST_SERVER_PATH
    
    # upload proxy configuration
    echo "Uploading proxy configuration to $TEST_SERVER_PATH/test-ikon.cfg"
    echo "The first time, you will have to add the proxy configuration to /etc/pound.cfg"
    scp deploy/test-ikon.cfg $TEST_USERNAME@$TEST_SERVER_IP:$TEST_SERVER_PATH

    # upload docker container startup scripts
    scp install/load.sh $TEST_USERNAME@$TEST_SERVER_IP:$TEST_SERVER_PATH
    scp install/import.sh $TEST_USERNAME@$TEST_SERVER_IP:$TEST_SERVER_PATH
    scp install/start.sh $TEST_USERNAME@$TEST_SERVER_IP:$TEST_SERVER_PATH
    scp mfn_fp.ini $TEST_USERNAME@$TEST_SERVER_IP:$TEST_SERVER_PATH
    ssh $TEST_USERNAME@$TEST_SERVER_IP "mkdir -p $TEST_SERVER_PATH/ikon-smw-stack"
    scp ./ikon-smw-stack/ikon_smw_test.sh $TEST_USERNAME@$TEST_SERVER_IP:$TEST_SERVER_PATH/ikon-smw-stack
    scp ./ikon-smw-stack/mariadb-custom.cnf $TEST_USERNAME@$TEST_SERVER_IP:$TEST_SERVER_PATH/ikon-smw-stack

    # cleanup
    rm /tmp/$DB_CONTAINER.tar
    rm /tmp/$SMW_CONTAINER.tar
    rm /tmp/dump.sql
    rm -rf /tmp/images
}

dump_media() {
    echo "Dumping media dir to /tmp/images"
    rm -f /tmp/images
    docker cp $SMW_CONTAINER:$MW_DOCKERDIR/images /tmp/
}

dump_db() {     
    # read database root password from input, if not set in config.ini
    if [ -z ${MYSQL_ROOT_PASSWORD+x} ]; then read -s -p "Password for database root: " MYSQL_ROOT_PASSWORD; fi
    echo "";
    
    # read mediawiki database name from input, if not set in config.ini
    if [ -z ${MYSQL_DATABASE+x} ]; then read -p "Name of the database used by this mediawiki: " MYSQL_DATABASE; fi
    echo "";
    
    export DB_CONTAINER
    export MYSQL_ROOT_PASSWORD
    export MYSQL_DATABASE
    
    # dump database
    echo "Dumping database to /tmp/dump.sql"
    docker exec -ti $DB_CONTAINER  script -q -c "/usr/bin/mysqldump -uroot -p$MYSQL_PASSWORD $MYSQL_DATABASE > /tmp/dump.sql"
    # Copy the dump to the host
    rm -f /tmp/dump.sql
    docker cp $DB_CONTAINER:/tmp/dump.sql /tmp/dump.sql
    # Cleanup
    docker exec -ti $DB_CONTAINER  script -q -c "rm /tmp/dump.sql"
}

killallimages() {
    docker rm -f $(docker ps -a -q) && docker rmi -f $(docker images -q) && docker rmi -f $(docker images -a -q)
    docker network rm $NETWORK
    service docker stop
    rm -rf /var/lib/docker/aufs
    rm -rf /var/lib/docker/image/aufs
    rm -f /var/lib/docker/linkgraph.db
    rm -rf /var/lib/docker/volumes
    service docker start
    df -h
}

dropalldata() {
    rm -rf $UPLOAD_MOUNT
    rm -rf $DB_MOUNT
}

case $opt in 
    0)
        usage
        ;;
    1)
        build
	stop
	echo "Now start the containers and import a database dump."
        ;;
    2)
        configure
        start
	echo "If this is the first run, you may need to import a database dump."
        ;;
    3)
        stop
        ;;
    4)
        importwiki
        feedback
        ;;
    5)
        configure
        import
        createSysop
        feedback
        ;;
    6)
        configure
        deploy_test
        ;;
    7)
        configure
        dump_db
        ;;
    13)
        killallimages
	dropalldata
        ;;      
    *)
        echo "Unbekannte Option"
        ;;
esac
