Docker scripts for creating a semantic MediaWiki with the extensions and layout as used at the Museum für Naturkunde Berlin.

## Creating a new wiki project
Create a new project for your wiki. Do not make it public. Add the public docker scripts as submodules.
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

