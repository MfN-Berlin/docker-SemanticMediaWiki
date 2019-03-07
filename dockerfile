FROM toniher/nginx-php:latest

LABEL Description="This image is used to start semantic MediaWiki" Vendor="Museum für Naturkunde Berlin" Version="0.3"

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
ARG ONTOLOGY
ARG UserFunctions_DOWNLOAD_URL
ARG HeaderTabs_DOWNLOAD_URL
ARG WikiCategoryTagCloud_DOWNLOAD_URL
ARG SimpleChanges_DOWNLOAD_URL
ARG PDFEmbed_DOWNLOAD_URL
ARG LDAP_DOWNLOAD_URL
ARG VisualEditor_DOWNLOAD_URL
ARG ParserFunctions_DOWNLOAD_URL
ARG CategoryTree_DOWNLOAD_URL
ARG WikiEditor_DOWNLOAD_URL
ARG PageForms_DOWNLOAD_URL
ARG Arrays_DOWNLOAD_URL
ARG CookieWarning_DOWNLOAD_URL
ARG PDFEmbed_DOWNLOAD_URL
ARG HTMLets_DOWNLOAD_URL

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
RUN apt-get update \
    && apt-get -y install nano vim net-tools zip curl git xz-utils make
    
##############################
#
# Mediawiki core
#
##############################
RUN MEDIAWIKI_DOWNLOAD_URL="https://releases.wikimedia.org/mediawiki/$MEDIAWIKI_VERSION/mediawiki-$MEDIAWIKI_FULL_VERSION.tar.gz"; \
	set -x; \
	mkdir -p $MW_DOCKERDIR \
    && curl -fSL "$MEDIAWIKI_DOWNLOAD_URL" -o mediawiki.tar.gz \
    && tar -xf mediawiki.tar.gz -C $MW_DOCKERDIR --strip-components=1 \
    && set -x; echo $MYSQL_HOST >> /tmp/startpath; cat /tmp/startpath \
    && set -x; echo "Host is $MYSQL_HOST"

#######################
#
# Node
#
#######################
RUN groupadd --gid 1000 node \
  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

ENV NODE_VERSION 10.8.0

RUN curl -fsSLO --compressed https://nodejs.org/dist/v10.8.0/node-v10.8.0-linux-x64.tar.xz \
  && tar -xJf "node-v10.8.0-linux-x64.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
  && rm "node-v10.8.0-linux-x64.tar.xz" \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs

ENV YARN_VERSION 1.9.2

RUN curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
  && curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc" \
  && mkdir -p /opt \
  && tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/ \
  && ln -s /opt/yarn-v$YARN_VERSION/bin/yarn /usr/local/bin/yarn \
  && ln -s /opt/yarn-v$YARN_VERSION/bin/yarnpkg /usr/local/bin/yarnpkg \
  && rm yarn-v$YARN_VERSION.tar.gz

CMD [ "node" ]

##############################
#
# Webserver
#
##############################
# nginx configuration
COPY nginx.conf /etc/nginx/
RUN mkdir /etc/nginx/sites-available
COPY sites-available-default /etc/nginx/sites-available/default
COPY mime.types /etc/nginx/mime.types
RUN mkdir /etc/nginx/sites-enabled \
    && ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

##############################
#
# Database
#
##############################
RUN echo MYSQL_DATABASE: $MYSQL_DATABASE
RUN cd $MW_DOCKERDIR; \
    php maintenance/install.php \
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
RUN cd $MW_DOCKERDIR; \
    composer update --no-dev \
    && php maintenance/update.php \
    \
# Update Semantic MediaWiki
    && php extensions/SemanticMediaWiki/maintenance/rebuildData.php -ftpv \
    && php extensions/SemanticMediaWiki/maintenance/rebuildData.php -v \
    && php maintenance/runJobs.php

############################
#
# Extensions (non-composer)
#
############################
# prepare extensions directory
RUN set -x; cd $MW_DOCKERDIR; mkdir -p extensions \
    	\
# download and untar the UserFunctions extension
	&& curl -sL $UserFunctions_DOWNLOAD_URL -o UserFunctions.tar.gz \
	&& tar -xf UserFunctions.tar.gz -C extensions \
	&& rm UserFunctions.tar.gz \
	\
# download and untar the HeaderTabs extension
	&& curl -fSL $HeaderTabs_DOWNLOAD_URL -o HeaderTabs.tar.gz \
	&& tar -xf HeaderTabs.tar.gz -C extensions \
	&& rm HeaderTabs.tar.gz \
	\
# download and untar the WikiCategoryTagCloud extension
	&& curl -fSL $WikiCategoryTagCloud_DOWNLOAD_URL -o WikiCategoryTagCloud.tar.gz \
	&& tar -xf WikiCategoryTagCloud.tar.gz -C extensions \
	&& rm WikiCategoryTagCloud.tar.gz \
	\
# download and untar the SimpleChanges extension
	&& curl -fSL $SimpleChanges_DOWNLOAD_URL -o SimpleChanges.tar.gz \
	&& tar -xf SimpleChanges.tar.gz -C extensions \
	&& rm SimpleChanges.tar.gz \
	\
# download and untar the VisualEditor extension
  	&& curl -fSL $VisualEditor_DOWNLOAD_URL -o VisualEditor.tar.gz \
	&& tar -xf VisualEditor.tar.gz -C extensions \
	&& rm VisualEditor.tar.gz \
	\
# download and untar the WikiEditor extension
	&& curl -fSL $WikiEditor_DOWNLOAD_URL -o WikiEditor.tar.gz \
	&& tar -xf WikiEditor.tar.gz -C extensions \
	&& rm WikiEditor.tar.gz \
	\
# download and untar the CategoryTree extension
	&& curl -fSL $CategoryTree_DOWNLOAD_URL -o CategoryTree.zip \
	&& unzip CategoryTree.zip -d extensions \
	&& mv extensions/mediawiki-extensions-CategoryTree-master extensions/CategoryTree \
	&& rm CategoryTree.zip \
	\
# LDAP
	&& apt-get install -y php-ldap \
	\
# download and untar the LDAP extension
	&& curl -fSL $LDAP_DOWNLOAD_URL -o Ldap.tar.gz \
	&& tar -xf Ldap.tar.gz -C extensions \
	&& rm Ldap.tar.gz \
	\
# download and untar the ParserFunctions extension
  	&& curl -fSL $ParserFunctions_DOWNLOAD_URL -o ParserFunctions.tar.gz \
	&& tar -xf ParserFunctions.tar.gz -C extensions \
	&& rm ParserFunctions.tar.gz \
	\
# download and untar the PageForms extension
	&& curl -fSL $PageForms_DOWNLOAD_URL -o PageForms.zip \
	&& unzip PageForms.zip -d extensions \
	&& mv extensions/mwPageForms-master extensions/PageForms \
	&& rm PageForms.zip \
	\
# download and untar the Arrays extension
  	&& curl -fSL $Arrays_DOWNLOAD_URL -o Arrays.tar.gz \
	&& tar -xf Arrays.tar.gz -C extensions \
	&& rm Arrays.tar.gz \
	\
# download and untar the CookieWarning extension
  	&& curl -fSL $CookieWarning_DOWNLOAD_URL -o CookieWarning.tar.gz \
	&& tar -xf CookieWarning.tar.gz -C extensions \
	&& rm CookieWarning.tar.gz \
	\
# download and untar the PDFEmbed extension
	&& curl -fSL $PDFEmbed_DOWNLOAD_URL -o PDFEmbed.zip \
	&& unzip PDFEmbed.zip -d extensions \
	&& mv extensions/PDFEmbed-master extensions/PDFEmbed \
	&& rm PDFEmbed.zip \
	\
# download and untar the HTMLets extension
  	&& curl -fSL $HTMLets_DOWNLOAD_URL -o HTMLets.tar.gz \
	&& tar -xf HTMLets.tar.gz -C extensions \
	&& rm HTMLets.tar.gz 

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


##############################
#
# Parsoid
#
##############################

RUN wget https://github.com/wikimedia/parsoid/archive/v0.8.1.tar.gz -O parsoid.tar.gz
RUN tar -xvf parsoid.tar.gz
RUN mv parsoid-0.8.1/ parsoid
RUN cd parsoid \
&& npm install

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
RUN chown -R root:root $MW_DOCKERDIR/ \
    \
# uploads belong to webserver user
  &&  mkdir -p $MW_DOCKERDIR/images \
  && touch $MW_DOCKERDIR/images/dummy \
  && chown -R www-data:www-data $MW_DOCKERDIR/images \
  \
# cache belongs to webserver user
  && chown -R www-data:www-data $MW_DOCKERDIR/cache

#######################
#
# Cleanup
#
#######################

# cleanup installation files
RUN rm /mediawiki.tar.gz \
    \
# Remove all unecessary things.
  && rm  -f $MW_DOCKERDIR/nginx.conf \
  && rm  -f $MW_DOCKERDIR/config.yaml \
  && rm  -f $MW_DOCKERDIR/config.tpl.yaml \
  && rm  -f $MW_DOCKERDIR/sites-available-default \
  && rm  -f $MW_DOCKERDIR/Dockerfile \
  && rm  -f $MW_DOCKERDIR/dockerfile \
  && rm  -f $MW_DOCKERDIR/*.conf \
  && rm  -f $MW_DOCKERDIR/*.cnf \
  && rm  -f $MW_DOCKERDIR/*~ \
  && rm  -f $MW_DOCKERDIR/*.sh \
  && rm  -f $MW_DOCKERDIR/LocalSettings.tpl.php \
  \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/*

#######################
#
# Start
#
#######################
#MetaLocalSettings to MW_DOCKERDIR
COPY MetaLocalSettings.php $MW_DOCKERDIR

# dir to store php-fpm socket
RUN mkdir -p mkdir /run/php

# Do this after cleanup, otherwise it gets deleted
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# run supervisor daemon to start apps
CMD ["/usr/bin/supervisord"]

