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
$wgLanguageCode = "de-formal";
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
#$wgExternalLinkTarget = '_blank';

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
# Set to 1 when using scripts that require bot user.
$installation = 0;
if (!$installation) {
   # Anonymous users can only read whitelisted pages
   $wgGroupPermissions['*']['read'] = false;
   $wgGroupPermissions['*']['delete'] = false;
   $wgGroupPermissions['*']['protect'] = false;
   $wgGroupPermissions['*']['upload'] = false;
   $wgGroupPermissions['*']['createpage'] = false;
   $wgGroupPermissions['*']['edit'] = false;
   $wgGroupPermissions['*']['move'] = false;

   # Logged-in users can read all pages
   $wgGroupPermissions['user']['read'] = true;
   $wgGroupPermissions['*']['embed_pdf'] = true;

   # All logged-in users can edit pages in the article namespace
   $wgGroupPermissions['user']['edit'] = true;
   $wgGroupPermissions['user']['upload'] = false;
   $wgGroupPermissions['user']['createpage'] = false;
   $wgGroupPermissions['mfnEditor']['edit'] = true;
   $wgGroupPermissions['mfnEditor']['delete'] = true;
   $wgGroupPermissions['mfnEditor']['protect'] = true;
   $wgGroupPermissions['mfnEditor']['upload'] = true;
   $wgGroupPermissions['mfnEditor']['createpage'] = true;
   $wgGroupPermissions['mfnEditor']['editinterface'] = true;
} else {
   $wgGroupPermissions['*']['protect'] = true;
   $wgGroupPermissions['*']['editprotected'] = true;
}

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

# Allow users on the local network to read-only access
function isValidLocalIP($ip) {
        // IPs should be local
        if (substr($ip, 0, 8)!="192.168.") {
                return false;
        }
        // validate IPs
        if (!filter_var ($ip, FILTER_VALIDATE_IP)) {
                return false;
        }
        return true;
}
function isLocalClient(){
    // Nothing to do without any reliable information
    if (!isset ($_SERVER['REMOTE_ADDR'])) {
        return false;
    }

    // Header that is used by the trusted proxy to refer to
    // the original IP
    $proxy_header = "HTTP_X_FORWARDED_FOR";

    // List of all the proxies that are known to handle 'proxy_header'
    // in known, safe manner
    $trusted_proxy = "192.168.100.10";

    if (array_key_exists($proxy_header, $_SERVER)) {
        // Header can contain multiple IP-s of proxies that are passed through.
        $proxy_list = array_map('trim', explode (",", $_SERVER[$proxy_header]));
        // Trusted prroxy should be in IP list
        if (in_array($trusted_proxy, $proxy_list)) {
                foreach ($proxy_list as $ip) {
                        if (!isValidLocalIP($ip)) return false;
                }
                return true;
        } else {
                return false;
        }
    } elseif (!isValidLocalIP($_SERVER['REMOTE_ADDR'])) {
        return false;
    } else {
        return true;
    }
}

#print_r($_SERVER);
#print(isLocalClient());
if(isLocalClient()) {
    $wgGroupPermissions['*']['read'] = true;
}

# Whitelist
$wgWhitelistRead = array(
	"Special:UserLogin",
	"Special:UserLogout", "Special:PasswordReset",
	"MediaWiki:Common.css", "MediaWiki:Common.js",
	"@@WikiName@@:Datenschutz", "@@WikiName@@:Impressum",
	"MediaWiki:About", "FAQ_@@WikiName@@"
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

# Experimentell: Bilder und Links in Texte
# see: https://www.semantic-mediawiki.org/wiki/Help:$smwgLinksInValues
$smwgLinksInValues = SMW_LINV_OBFU;

#############################
#
# Allow custom HTML snippets
# (e.g. the scroller on the home page)
#
#############################
require_once "$IP/extensions/HTMLets/HTMLets.php";
$wgHTMLetsDirectory = "$IP/htmlets";

#############################
#
# Restrict search
# 
#############################

$wgNamespacesToBeSearchedDefault = [
        NS_MAIN => true,
];
