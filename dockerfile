FROM toniher/nginx-php:latest

LABEL Description="This image is used to start semantic MediaWiki" Vendor="Museum für Naturkunde Berlin" Version="0.2"

###################################
#
# get ARGS from configuration file
# Usage: README.md
#
###################################

ARG MEDIAWIKI_VERSION
ARG MEDIAWIKI_FULL_VERSION
ARG MYSQL_HOST
ARG MYSQL_DATABASE
ARG MYSQL_USER
ARG MYSQL_PASSWORD
ARG MYSQL_PREFIX
ARG MW_PASSWORD
ARG MW_SCRIPTPATH
ARG MW_DOCKERDIR
ARG MW_SKIN
ARG UPLOAD_MOUNT
ARG MW_WIKILANG
ARG MW_WIKINAME
ARG MW_WIKIUSER
ARG MW_EMAIL
ARG DOMAIN_NAME
ARG PROTOCOL
ARG UserFunctions_DOWNLOAD_URL
ARG HeaderTabs_DOWNLOAD_URL
ARG WikiCategoryTagCloud_DOWNLOAD_URL
ARG SimpleChanges_DOWNLOAD_URL
ARG Lockdown_DOWNLOAD_URL
ARG PDFEmbed_DOWNLOAD_URL
ARG LDAP_DOWNLOAD_URL
ARG VisualEditor_DOWNLOAD_URL
ARG ParserFunctions_DOWNLOAD_URL
ARG CategoryTree_DOWNLOAD_URL
ARG WikiEditor_DOWNLOAD_URL
ARG PageForms_DOWNLOAD_URL

#########################
#
# Docker instructions
#
#########################

# Webserver port
EXPOSE 80

# Mountpoint for uploads
VOLUME $MW_DOCKERDIR/images

##############################
#
# general utilities
#
##############################
RUN apt-get update
RUN apt-get -y install nano
RUN apt-get -y install vim
RUN apt-get -y install net-tools
RUN apt-get -y install zip
RUN apt-get install curl

##############################
#
# Mediawiki core
#
##############################
# https://www.mediawiki.org/keys/keys.txt
RUN gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys \
	441276E9CCD15F44F6D97D18C119E1A64D70938E \
	41B2ABE817ADD3E52BDA946F72BC1C5D23107F8A \
	162432D9E81C1C618B301EECEE1F663462D84F01 \
	1D98867E82982C8FE0ABC25F9B69B3109D3BB7B0 \
	3CEF8262806D3F0B6BA1DBDD7956EE477F901A30 \
	280DB7845A1DCAC92BB5A00A946B02565DC00AA7

RUN MEDIAWIKI_DOWNLOAD_URL="https://releases.wikimedia.org/mediawiki/$MEDIAWIKI_VERSION/mediawiki-$MEDIAWIKI_FULL_VERSION.tar.gz"; \
	set -x; \
	mkdir -p $MW_DOCKERDIR \
	&& curl -fSL "$MEDIAWIKI_DOWNLOAD_URL" -o mediawiki.tar.gz \
	&& curl -fSL "${MEDIAWIKI_DOWNLOAD_URL}.sig" -o mediawiki.tar.gz.sig \
	&& gpg --verify mediawiki.tar.gz.sig \
	&& tar -xf mediawiki.tar.gz -C $MW_DOCKERDIR --strip-components=1

RUN set -x; echo $MYSQL_HOST >> /tmp/startpath; cat /tmp/startpath

RUN set -x; echo "Host is $MYSQL_HOST"

##############################
#
# Webserver
#
##############################
# nginx configuration
COPY nginx.conf /etc/nginx/
RUN mkdir /etc/nginx/sites-available
COPY sites-available-default /etc/nginx/sites-available/default
RUN mkdir /etc/nginx/sites-enabled
RUN ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Adding extra domain name
RUN sed -i "s/localhost/localhost $DOMAIN_NAME/" /etc/nginx/conf.d/default.conf

##############################
#
# Database
#
##############################
RUN echo MYSQL_DATABASE: $MYSQL_DATABASE
RUN cd $MW_DOCKERDIR; php maintenance/install.php \
		--dbname "$MYSQL_DATABASE" \
		--dbpass "$MYSQL_PASSWORD" \
		--dbserver "$MYSQL_HOST" \
		--dbtype mysql \
		--dbprefix "$MYSQL_PREFIX" \
		--dbuser "$MYSQL_USER" \
		--installdbpass "$MYSQL_PASSWORD" \
		--installdbuser "$MYSQL_USER" \
		--pass "$MW_PASSWORD" \
		--scriptpath /"$MW_SCRIPTPATH" \
		--lang "$MW_WIKILANG" \
		"${MW_WIKINAME}" "${MW_WIKIUSER}";

##############################
#
# Composer
#
##############################
# copy composer file from host
COPY composer.local.json $MW_DOCKERDIR

# run composer update (creates database tables)
RUN cd $MW_DOCKERDIR; composer update --no-dev;
RUN cd $MW_DOCKERDIR; php maintenance/update.php;

# Update Semantic MediaWiki
RUN cd $MW_DOCKERDIR; php extensions/SemanticMediaWiki/maintenance/rebuildData.php -ftpv;
RUN cd $MW_DOCKERDIR; php extensions/SemanticMediaWiki/maintenance/rebuildData.php -v;
RUN cd $MW_DOCKERDIR; php maintenance/runJobs.php;

# Install nodejs (not from distribution, as outdated)
#RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -
#RUN apt-get -y install nodejs

# Install parsoid
#RUN apt-get -y install apt-transport-https
#RUN useradd parsoid --no-create-home --home-dir /usr/lib/parsoid --shell /usr/sbin/nologin
#RUN apt-key advanced --keyserver pgp.mit.edu --recv-keys 90E9F83F22250DD7

#RUN echo "deb https://releases.wikimedia.org/debian jessie-mediawiki main" | tee /etc/apt/sources.list.d/parsoid.list
#RUN apt-get update
#RUN apt-get -y install parsoid --no-install-recommends

#ENV NODE_PATH /usr/lib/parsoid/node_modules:/usr/lib/parsoid/src

#COPY parsoid_config.yaml /usr/lib/parsoid/src/config.yaml
#COPY parsoid_config.yaml /etc/mediawiki/parsoid/config.yaml

############################
#
# Extensions (non-composer)
#
############################
# prepare extensions directory
RUN set -x; cd $MW_DOCKERDIR; mkdir -p extensions

# download and untar the UserFunctions extension
RUN cd $MW_DOCKERDIR; \
	curl -sL $UserFunctions_DOWNLOAD_URL -o UserFunctions.tar.gz \
	&& tar -xf UserFunctions.tar.gz -C extensions \
	&& rm UserFunctions.tar.gz
	
# download and untar the HeaderTabs extension
RUN cd $MW_DOCKERDIR; \
	curl -fSL $HeaderTabs_DOWNLOAD_URL -o HeaderTabs.tar.gz \
	&& tar -xf HeaderTabs.tar.gz -C extensions \
	&& rm HeaderTabs.tar.gz

# download and untar the WikiCategoryTagCloud extension
RUN cd $MW_DOCKERDIR; \
	curl -fSL $WikiCategoryTagCloud_DOWNLOAD_URL -o WikiCategoryTagCloud.tar.gz \
	&& tar -xf WikiCategoryTagCloud.tar.gz -C extensions \
	&& rm WikiCategoryTagCloud.tar.gz

# download and untar the SimpleChanges extension
RUN cd $MW_DOCKERDIR; \
	curl -fSL $SimpleChanges_DOWNLOAD_URL -o SimpleChanges.tar.gz \
	&& tar -xf SimpleChanges.tar.gz -C extensions \
	&& rm SimpleChanges.tar.gz

# download and untar the Lockdown extension
RUN cd $MW_DOCKERDIR; \
	curl -fSL $Lockdown_DOWNLOAD_URL -o Lockdown.tar.gz \
	&& tar -xf Lockdown.tar.gz -C extensions \
	&& mv extensions/mediawiki-extensions-Lockdown-fixed_1.27 extensions/Lockdown \
	&& rm Lockdown.tar.gz
	
# download and untar the PDFEmbed extension
RUN cd $MW_DOCKERDIR; \
	curl -fSL $PDFEmbed_DOWNLOAD_URL -o PDFEmbed.zip \
	&& unzip PDFEmbed.zip -d extensions \
	&& mv extensions/PDFEmbed-2.0.0 extensions/PDFEmbed \
	&& rm PDFEmbed.zip
	
# download and untar the VisualEditor extension
RUN cd $MW_DOCKERDIR; \
	curl -fSL $VisualEditor_DOWNLOAD_URL -o VisualEditor.tar.gz \
	&& tar -xf VisualEditor.tar.gz -C extensions \
	&& rm VisualEditor.tar.gz
	
# download and untar the WikiEditor extension
RUN cd $MW_DOCKERDIR; \
	curl -fSL $WikiEditor_DOWNLOAD_URL -o WikiEditor.tar.gz \
	&& tar -xf WikiEditor.tar.gz -C extensions \
	&& rm WikiEditor.tar.gz

# download and untar the CategoryTree extension
RUN cd $MW_DOCKERDIR; \
	curl -fSL $CategoryTree_DOWNLOAD_URL -o CategoryTree.zip \
	&& unzip CategoryTree.zip -d extensions \
	&& mv extensions/mediawiki-extensions-CategoryTree-master extensions/CategoryTree \
	&& rm CategoryTree.zip

# LDAP
RUN apt-get install -y php-ldap

# download and untar the LDAP extension
RUN cd $MW_DOCKERDIR; \
	curl -fSL $LDAP_DOWNLOAD_URL -o Ldap.tar.gz \
	&& tar -xf Ldap.tar.gz -C extensions \
	&& rm Ldap.tar.gz

# download and untar the ParserFunctions extension
RUN cd $MW_DOCKERDIR; \
	curl -fSL $ParserFunctions_DOWNLOAD_URL -o ParserFunctions.tar.gz \
	&& tar -xf ParserFunctions.tar.gz -C extensions \
	&& rm ParserFunctions.tar.gz

# download and untar the PageForms extension
RUN cd $MW_DOCKERDIR; \
	curl -fSL $PageForms_DOWNLOAD_URL -o PageForms.zip \
	&& unzip PageForms.zip -d extensions \
	&& mv extensions/mwPageForms-master extensions/PageForms \
	&& rm PageForms.zip

#####################
#
# Skin and UI
#
#####################
# copy the custom skin to the skins directory
COPY skins/naturkunde $MW_DOCKERDIR/skins

# Logo
COPY $MW_LOGO $MW_DOCKERDIR

# Background image
COPY $MW_BG $MW_DOCKERDIR

#######################
#
# Update script
#
#######################
# make sure that ALL EXTENSIONS and SKINS required in LocalSettings are available before starting the update script.
RUN php $MW_DOCKERDIR/maintenance/update.php;
# Starting processes
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

#######################
#
# Security
#
#######################
# everything belongs to root (exceptions below)
RUN chown -R root:root $MW_DOCKERDIR/

# uploads belong to webserver user
RUN mkdir -p $MW_DOCKERDIR/images
RUN touch $MW_DOCKERDIR/images/dummy
RUN chown -R www-data:www-data $MW_DOCKERDIR/images

# cache belongs to webserver user
RUN chown -R www-data:www-data $MW_DOCKERDIR/cache

#######################
#
# Cleanup
#
#######################

# cleanup installation files
RUN rm /mediawiki.tar.gz
RUN rm /mediawiki.tar.gz.sig

# Somehow everything gets copied to $MW_DOCKERDIR
# So remove all unecessary things.
RUN rm  -f $MW_DOCKERDIR/nginx.conf
RUN rm  -f $MW_DOCKERDIR/parsoid_config.yaml
RUN rm  -f $MW_DOCKERDIR/sites-available-default
RUN rm  -f $MW_DOCKERDIR/Dockerfile
RUN rm  -f $MW_DOCKERDIR/dockerfile
RUN rm  -f $MW_DOCKERDIR/*.conf
RUN rm  -f $MW_DOCKERDIR/*.cnf
RUN rm  -f $MW_DOCKERDIR/*~
RUN rm  -f $MW_DOCKERDIR/*.sh
RUN rm  -f $MW_DOCKERDIR/LocalSettings.tpl.php


#######################
#
# Start
#
#######################
# Do this after cleanup, otherwise it gets deleted
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
# run supervisor daemon to start apps
CMD ["/usr/bin/supervisord"]

