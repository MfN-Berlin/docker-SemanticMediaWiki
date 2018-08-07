<?php
# Further documentation for configuration settings may be found at:
# https://www.mediawiki.org/wiki/Manual:Configuration_settings

# Protect against web entry
if ( !defined( 'MEDIAWIKI' ) ) {
	exit;
}

#Include MetaLocalSettings
include_once 'MetaLocalSettings.php';

#############################
#
#     Debug
#
#############################
// For debugging:
#ini_set("display_errors", "1");
### Debug
#$wgDebugLogFile = "$IP/debug.log"; # "$IP/debug.log";leave it empty to prevent debug logs, as they become fast huge files

## Uncomment this to disable output compression
# $wgDisableOutputCompression = true;

#############################
#
#     Paths & Names
#
#############################

$wgSitename = "@@WikiName@@";

## The URL base path to the directory containing the wiki;
## defaults for all runtime URL paths are based off of this.
## For more information on customizing the URLs
## (like /w/index.php/Page_title to /wiki/Page_title) please see:
## https://www.mediawiki.org/wiki/Manual:Short_URL
$wgScriptPath = "@@ScriptPath@@";
$wgArticlePath = "@@ScriptPath@@/$1";
$wgUsePathInfo = true;

## The URL path to static resources (images, scripts, etc.)
$wgResourceBasePath = $wgScriptPath;

## UPO means: this is also a user preference option

$wgEnableEmail = true;
$wgEnableUserEmail = true; # UPO

$wgEmergencyContact = "@@Email@@";
$wgPasswordSender = "@@Email@@";

$wgEnotifUserTalk = false; # UPO
$wgEnotifWatchlist = false; # UPO
$wgEmailAuthentication = true;

$wgMetaNamespace = "@@WikiName@@";
$wgLocalInterwiki = strtolower( "@@WikiName@@" );

#############################
#
#     Database
#
#############################

$wgDBtype = "mysql";

# Docker network address where the database is, as given by (on the host):
# > docker network inspect bridge

# This has to be an IP on the default network for creating the image
# Change it later when deploying the image
$wgDBserver = "@@dbServer@@";

$wgDBname = "@@database@@";
$wgDBuser = "@@dbUser@@";
$wgDBpassword = "@@dbPass@@";
$wgDBprefix = "@@dbprefix@@";

# MySQL table options to use during installation or update
$wgDBTableOptions = "ENGINE=InnoDB, DEFAULT CHARSET=binary";

# Experimental charset support for MySQL 5.0.
$wgDBmysql5 = false;

## Shared memory settings
$wgMainCacheType = CACHE_NONE;
$wgMemCachedServers = [];

#############################
#
#     User interface
#
#############################

# Site language code, should be one of the list in ./languages/data/Names.php
$wgLanguageCode = "de";
## Default skin: you can change the default skin. Use the internal symbolic
## names, ie 'vector', 'monobook':
$wgDefaultSkin = "@@skin@@";

# Enabled skins.
# The following skins were automatically enabled:
wfLoadSkin( 'CologneBlue' );
wfLoadSkin( 'Modern' );
wfLoadSkin( 'MonoBook' );
wfLoadSkin( 'Vector' );

# loading the skin Naturkunde the old way
require_once "$IP/skins/@@skin@@/@@skintpl@@";

# The URL path to the logo.
$wgLogo = "@@Logo@@";

# Backround image and colour
#$wgMainPageBackgroundImage = "@@bgImage@@";
#$wgMainPageBackgroundColor = "@@bgColor@@";

# Hide the navigation tabs (edit, discussion) if on the Homepage (only works with skin 'Naturkunde')
#$wgMainPageHideNav = true;

# Open external links in new tab (useful when working with many forms)
$wgExternalLinkTarget = '_blank';

# Allow pages to customize the title (necessary for localization of imported ontologies).
$wgRestrictDisplayTitle = false;

# Allow using icons from wikipedia
$wgAllowExternalImagesFrom = "https://upload.wikimedia.org/";

# enable string functions
$wgPFEnableStringFunctions = true;

########################
#
# VisualEditor
#
########################
wfLoadExtension( 'VisualEditor' );

# Enable by default for everybody
$wgDefaultUserOptions['visualeditor-enable'] = 1;

# Optional: Set VisualEditor as the default for anonymous users
# otherwise they will have to switch to VE
$wgDefaultUserOptions['visualeditor-editor'] = "visualeditor";

# Don't allow users to disable it
$wgHiddenPrefs[] = 'visualeditor-enable';

$wgVirtualRestConfig['modules']['parsoid'] = array(
#// URL to the Parsoid instance
#// Use port 8142 if you use the Debian package
	'url' => 'http://localhost:8000',
# Parsoid "domain" (optional)
	'domain' => '@@smwContainer@@',
);

$wgVisualEditorSupportedSkins[] = 'naturkunde';

#############################
#
# Autorisation
#
#############################

# Anonymous users can only read whitelisted pages
$wgGroupPermissions['*']['read'] = false;

# Logged-in users can read all pages
$wgGroupPermissions['user']['read'] = true;
$wgGroupPermissions['*']['embed_pdf'] = true;

# only users with role mfnEditor can edit
$wgGroupPermissions['*']['edit'] = false;
$wgGroupPermissions['user']['edit'] = false;
$wgGroupPermissions['mfnEditor']['edit'] = true;

# Allow Parsoid to use the api.
# See: http://www.mediawiki.org/wiki/Talk:Parsoid#Running_Parsoid_on_a_.22private.22_wiki_-_AccessDeniedError
# Also override Lockdown
if ( array_key_exists("REMOTE_ADDR", $_SERVER) && gethostbyaddr($_SERVER["REMOTE_ADDR"])=="localhost" ) {
        $wgGroupPermissions['*']['read'] = true;
        $wgNamespacePermissionLockdown[NS_MAIN]['read'] = array('*');
        $wgNamespacePermissionLockdown[NS_CONFIDENTIAL]['read'] = array('*');
        $wgNamespacePermissionLockdown[NS_CATEGORY]['read'] = array('*');
        $wgGroupPermissions['*']['editinterface'] = true;
}

$wgRedirectOnLogin = "Hauptseite";

# Whitelist
$wgWhitelistRead = array(
	"Hauptseite", "Main Page", "Special:UserLogin",
	"Special:UserLogout", "Special:PasswordReset",
	"MediaWiki:Common.css", "MediaWiki:Common.js",
	"@@WikiName@@:Datenschutz", "@@WikiName@@:Impressum"
);

#############################
#
# Authentication (LDAP)
# https://blog.ryandlane.com/2009/03/23/using-the-ldap-authentication-plugin-for-mediawiki-the-basics-part-1/  #
#
#############################
require_once ("$IP/extensions/LdapAuthentication/LdapAuthentication.php");

$wgAuth = new LdapAuthenticationPlugin();

$wgLDAPDomainNames = array("MUSEUM");
$wgLDAPServerNames = array("MUSEUM" => "@@LDAP_URL@@");
$wgLDAPSearchStrings = array("MUSEUM" => "MUSEUM\\USER-NAME");
$wgLDAPEncryptionType = array("MUSEUM" => "clear");
$wgLDAPUseLocal = true;
$wgMinimalPasswordLength = 1;
$wgLDAPPort = array("MUSEUM" => 389);
$wgLDAPGroupsUseMemberOf = array("MUSEUM" => true);

# Required for first login. Only works if user can authenticate.
$wgGroupPermissions['*']['autocreateaccount'] = true;
