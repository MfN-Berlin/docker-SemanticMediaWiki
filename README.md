Docker scripts for creating a semantic MediaWiki with the extensions and layout as used at the Museum für Naturkunde Berlin.

## Creating a new wiki project
Create a new project for your wiki. Do not make it public, as sensitive configuration will be saved here. Add the public docker scripts as submodules.
```
git submodule add git@github.com:MfN-Berlin/docker-SemanticMediaWiki.git
```

## Configuration
Run ```docker-SemanticMediaWiki/configure``` to create a configuration file.
The configuration will be saved to ```config.ini``` in the working directory.
```
chmod +x docker-SemanticMediaWiki/configure
docker-SemanticMediaWiki/configure
```

## Create docker images
Docker images will be created on your local machine.
```
chmod +x docker-SemanticMediaWiki/smw.sh
docker-SemanticMediaWiki/smw.sh
```
and choose: ```1. Build new Docker Containers```

## Stopping and starting
To stop and start the docker images on your local machine, do:
```
docker-SemanticMediaWiki/smw.sh
```
and choose: ```2. Start Docker Containers``` or ```3. Stop Docker Containers```.

## Deleting docker images
To delete all docker images and other files from your local machine, call the smw.sk script as root
```
sudo docker-SemanticMediaWiki/smw.sh
```
and choose: ```13: Kill all images and volumes (run as root)```

