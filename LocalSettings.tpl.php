<?php
# Further documentation for configuration settings may be found at:
# https://www.mediawiki.org/wiki/Manual:Configuration_settings

# Protect against web entry
if ( !defined( 'MEDIAWIKI' ) ) {
	exit;
}

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

#########################################
#
#     Site administration and upgrade
#
#########################################

$wgSecretKey = "f443f65d863168cfe6d744a44becceb5ef79fd05203e878eb2b44535be910ab1";

# Changing this will log out all existing sessions.
$wgAuthenticationTokenVersion = "1";

# Site upgrade key. Must be set to a string (default provided) to turn on the
# web installer while LocalSettings.php is in place
$wgUpgradeKey = "50231b7eadebda3e";

# Path to the GNU diff3 utility. Used for conflict resolution.
$wgDiff3 = "/usr/bin/diff3";

## Set $wgCacheDirectory to a writable directory on the web server
## to make your wiki go slightly faster. The directory should not
## be publically accessible from the web.
$wgCacheDirectory = "$IP/cache";

## Disable create accounts
$wgGroupPermissions['*']['createaccount'] = false;

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
$wgMainPageBackgroundImage = "@@bgImage@@";
$wgMainPageBackgroundColor = "@@bgColor@@";

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

#############################
#
#     Special pages
#
#############################

## For attaching licensing metadata to pages, and displaying an
## appropriate copyright notice / icon. GNU Free Documentation
## License and Creative Commons licenses are supported so far.
$wgRightsPage = ""; # Set to the title of a wiki page that describes your license/copyright
$wgRightsUrl = "";
$wgRightsText = "";
$wgRightsIcon = "";

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

$wgVisualEditorParsoidURL = 'http://@@parsoidContainer@@:8000';

$wgVirtualRestConfig['modules']['parsoid'] = array(
#// URL to the Parsoid instance
#// Use port 8142 if you use the Debian package
	'url' => 'http://@@parsoidContainer@@:8000',
# Parsoid "domain" (optional)
	'domain' => '@@smwContainer@@',
# Parsoid "prefix" (optional)
#	'prefix' => 'localhost'
);

$wgVisualEditorSupportedSkins[] = 'naturkunde';

#####################################
#
# WikiEditor (for form input fields)
#
####################################
wfLoadExtension( 'WikiEditor' );
$wgDefaultUserOptions['usebetatoolbar'] = 1;
$wgDefaultUserOptions['usebetatoolbar-cgd'] = 1;
$wgEditToolbarGlobalEnable = true; ## CHECK LATER WHETHER NEEDED
$wgWikiEditorFeatures['toolbar']        = array( 'global'=>true,  'user'=>true );
$wgWikiEditorFeatures['dialogs']        = array( 'global'=>true,  'user'=>true );
$wgWikiEditorFeatures['toc']            = array( 'global'=>false, 'user'=>true );
$wgDefaultUserOptions['wikieditor-preview'] = 0;
$wgDefaultUserOptions['useeditwarning'] = 1;
$wgResourceLoaderDebug = true;

#############################
#
# Semantic MW
#
#############################

# SMW is installed by composer
# Page forms is installed by smw
wfLoadExtension('PageForms');

#############################
#
# Other Extensions
#
#############################

# Customize the Homepage if at MfN
require_once "$IP/extensions/UserFunctions/UserFunctions.php";
$wgUFEnablePersonalDataFunctions = true;
$wgUFAllowedNamespaces[NS_MAIN] = true;


# Tabs in forms (oldskool installation)
require_once "$IP/extensions/HeaderTabs/HeaderTabs.php";
$htDisableDefaultToc = true;
$htEditTabLink = false;
#$htStyle = 'style-name';

# Tag cloud
wfLoadExtension('WikiCategoryTagCloud');

# barebones Recent Changes list
require_once "$IP/extensions/SimpleChanges/SimpleChanges.php";
$wgSimpleChangesOnlyContentNamespaces = true;
$wgSimpleChangesOnlyLatest = true;
$wgSimpleChangesShowUser = true;

# PDF einbinden (für Präsentationen, in Landscape format)
wfLoadExtension( 'PDFEmbed' );
//Default width for the PDF object container.
$pdfEmbed['width'] = 870;
//Default height for the PDF object container.
$pdfEmbed['height'] = 625;
# Extra Zugriffsrecht
$wgGroupPermissions['mfnEditor']['embed_pdf'] = true;


#parser functions
wfLoadExtension( 'ParserFunctions' );
$wgPFEnableStringFunctions = true;

# CategoryTree
require_once "$IP/extensions/CategoryTree/CategoryTree.php";
$wgCategoryTreeSidebarRoot = 'Category:Inhaltsverzeichnis'; # Name of the category shown in the sidebar
$wgCategoryTreeForceHeaders = true;
$wgCategoryTreeSidebarOptions['mode'] = 'pages';
#$wgCategoryTreeSidebarOptions['mode'] = 'all'; # Show files in table of contents
$wgCategoryTreeSidebarOptions['hideprefix'] = CT_MODE_PAGES;
$wgCategoryTreeSidebarOptions['showcount'] = false;
$wgCategoryTreeSidebarOptions['hideroot'] = true;
$wgCategoryTreeSidebarOptions['namespaces'] = false;
$wgCategoryTreeSidebarOptions['depth'] = 1;

########################
#
# Namespaces
#
########################

const NS_PUBLIC = 600;
$wgExtraNamespaces[NS_PUBLIC] = 'Öffentlich';
$wgExtraNamespaces[601] = 'Öffentlich_Diskussion';
$wgContentNamespaces[] = NS_PUBLIC;
$smwgNamespacesWithSemanticLinks[NS_PUBLIC] = true;

const NS_CONFIDENTIAL = 700;
$wgExtraNamespaces[NS_CONFIDENTIAL] = 'Vertraulich';
$wgExtraNamespaces[701] = 'Vertraulich_Diskussion';
$wgContentNamespaces[] = NS_CONFIDENTIAL;
$smwgNamespacesWithSemanticLinks[NS_CONFIDENTIAL] = true;

const NS_TRASH = 800;
$wgExtraNamespaces[NS_TRASH] = 'Papierkorb';
$wgExtraNamespaces[801] = 'Papierkorb_Diskussion';
$wgContentNamespaces[] = NS_TRASH;
$smwgNamespacesWithSemanticLinks[NS_TRASH] = true;

const NS_GLOSSARY = 900;
$wgExtraNamespaces[NS_GLOSSARY] = 'Glossar';
$wgExtraNamespaces[901] = 'Glossar_Diskussion';
$wgContentNamespaces[] = NS_GLOSSARY;
$smwgNamespacesWithSemanticLinks[NS_GLOSSARY] = true;

const NS_GOAL = 910;
$wgExtraNamespaces[NS_GOAL] = 'Ziel';
$wgExtraNamespaces[911] = 'Ziel_Diskussion';
$wgContentNamespaces[] = NS_GOAL;
$smwgNamespacesWithSemanticLinks[NS_GOAL] = true;

const NS_STK = 920;
$wgExtraNamespaces[NS_STK] = 'Stakeholder';
$wgExtraNamespaces[921] = 'Stakeholder_Diskussion';
$wgContentNamespaces[] = NS_STK;
$smwgNamespacesWithSemanticLinks[NS_STK] = true;

#############################
#
# Autorisation
#
#############################

# Anonymous users can only read whitelisted pages
$wgGroupPermissions['*']['read'] = false;

# Logged-in users can read all pages
$wgGroupPermissions['user']['read'] = true;

# only users with role mfnEditor can edit
$wgGroupPermissions['*']['edit'] = false;
$wgGroupPermissions['user']['edit'] = false;
$wgGroupPermissions['mfnEditor']['edit'] = true;

# Allow Parsoid to use the api.
# See: http://www.mediawiki.org/wiki/Talk:Parsoid#Running_Parsoid_on_a_.22private.22_wiki_-_AccessDeniedError
# Also override Lockdown
if ( gethostbyaddr($_SERVER["REMOTE_ADDR"])=="ikon-parsoid.ikon-nw" ) {
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
	"Forschungsprojekte:Datenschutz", "Forschungsprojekte:Impressum"
);

###################
#
# Search settings
#
###################

$wgNamespacesToBeSearchedDefault[NS_PUBLIC] = true;

#############################
#
#     Media
#
#############################

## To enable image uploads, make sure the 'images' directory
## is writable, then set this to true:
$wgEnableUploads = true;

// Allow copy uploads from another wiki
$wgAllowCopyUploads = true;

$wgUseImageMagick = true;
$wgImageMagickConvertCommand = "/usr/bin/convert";
$wgMaxShellMemory = 307200;

## If you want to use image uploads under safe mode,
## create the directories images/archive, images/thumb and
## images/temp, and make them all writable. Then uncomment
## this, if it's not already uncommented:
#$wgHashedUploadDirectory = false;

## Set $wgCacheDirectory to a writable directory on the web server
## to make your wiki go slightly faster. The directory should not
## be publically accessible from the web.
$wgCacheDirectory = "$IP/cache";

## Each Wiki has its own media upload folder
#$wgUploadNavigationUrl = $wgScriptPath . '/index.php?title=Spezial:Hochladen';
#$wgUploadMissingFileUrl = $wgUploadNavigationUrl; # red link in page with missing files/imageshttps://biowikifarm.net/v-mfn/forschungsprojekte/media/1/1b/Symbol_microscope.png

#== Uploadable extensions ==
# By default only png, gif, jpg, strongly expanded here!
# There is also a blacklist, preventing html, php, exe, js and many many more
# Note: files without extension are a problem, see http://www.mediawiki.org/wiki/Manual:$wgFileExtensions
$wgFileExtensions = array(
// images
		'png', 'jpg', 'jpeg', 'gif', 'svg', 'tif', 'tiff' , 'xcf', 'vsd',
		// multimedia
		'mp3', 'ogg', 'wav', 'wma', 'swf', 'mpg', 'mpp', 'xml', 'txt', 'dat', 'pdf',
		// archives
		'zip', '7z', 'gz', 'tgz',
		// data
		'xml', 'txt', 'dat', 'pdf', 'ink',
		// office
		'odt', 'ods', 'odc', 'odp', 'odg', 'doc', 'docx', 'rtf', 'xls', 'xlsx', 'ppt', 'pptx', 'accdb'
);// end wgFileExtensions
# If following is turned off, users may override the warning for files not covered by $wgFileExtensions (and not in the blacklist)
$wgStrictFileExtensions = false;
## File type Blacklist exists both as extension AND Mimetype ($wgVerifyMimeType is true by default)!!!
$wgFileBlacklist = array(
# HTML may contain cookie-stealing JavaScript and web bugs
		'html', 'htm', 'js', 'jsb', 'mhtml', 'mht',
		# PHP scripts may execute arbitrary code on the server
		'php', 'phtml', 'php3', 'php4', 'php5', 'phps',
		# Other types that may be interpreted by some servers
		'shtml', 'jhtml', 'pl', 'py', 'cgi',
		# May contain harmful executables for Windows victimshttps://biowikifarm.net/v-mfn/forschungsprojekte/media/1/1b/Symbol_microscope.png
		'exe',
		'scr', 'dll', 'msi', 'vbs', 'bat', 'com', 'pif', 'cmd', 'vxd', 'cpl' );
$wgMimeTypeBlacklist= array(
		# HTML may contain cookie-stealing JavaScript and web bugs
		'text/html', 'text/javascript', 'text/x-javascript',  'application/x-shellscript',
		# PHP scripts may execute arbitrary code on the server
		'application/x-php', 'text/x-php',
		# Other types that may be interpreted by some servers
		'text/x-python', 'text/x-perl', 'text/x-bash', 'text/x-sh', 'text/x-csh',
		# Windows metafile, client-side vulnerability on some systems
		'application/x-msmetafile',
		'application/zip'
);

# InstantCommons allows wiki to use images from https://commons.wikimedia.org
$wgUseInstantCommons = false;

## If you use ImageMagick (or any other shell command) on a
## Linux server, this will need to be set to the name of an
## available UTF-8 locale
$wgShellLocale = "C.UTF-8";

## Autocomplete
$sfgAutocompletionURLs['wikispecies'] = 'http://10.0.2.15:10080/fp/autocomplete.php?source=wikispecies&search=<substr>';
$sfgAutocompletionURLs['instituten'] = 'http://10.0.2.15:10080/fp/autocomplete.php?source=wikipediacategory&category=Universität_in_Deutschland|Forschungsorganisation|Mitglied_der_Leibniz-Gemeinschaft&lang=de&search=<substr>';
$sfgAutocompletionURLs['laender'] = 'http://10.0.2.15:10080/fp/autocomplete.php?source=wikipediacategory&category=Mitgliedstaat_der_Vereinten_Nationen&lang=de&search=<substr>';
$sfgAutocompletionURLs['rvk'] = 'http://10.0.2.15:10080/fp/autocomplete.php?source=rvk&search=<substr>';
$sfgAutocompletionURLs['methoden'] = 'http://10.0.2.15:10080/fp/autocomplete.php?source=rvkfiltered&filter=methode|forschungsmethode&search=<substr>';

enableSemantics( 'museumfuernaturkunde.berlin/ikon' );

#############################
#
#     Authentication (LDAP)
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

