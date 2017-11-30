# WP Local Version

Version 2.0.0

A bash script to install [any WordPress version](https://wordpress.org/download/release-archive/) in the [Local by Flywheel](https://local.getflywheel.com/) app (without PHP errors or warnings)

This is a converted version for the Local app of the VVV auto site script [WP Nostalgia](https://github.com/keesiemeijer/wp-nostalgia).

Features:

* Ability to keep the `wp-content` folder between versions.
* WP-CLI is used to install WP versions > 3.5.2
* All other WP versions are installed by this script.
* To be able to install very early versions of WordPress this script fixes PHP errors by:
    * Hacking WP core files for WP versions < 2.0
    * Setting error_reporting off in:
        * wp-config.php (WP < 3.5.2)
        * wp-settings.php (WP < 3.0.0)

## PHP compatibility
Not all errors can be fixed (by a script) for the earlier WP versions on newer PHP environments. You have to pay attention what version of PHP is used with the WP version you install. Here's an overview of what PHP versions you can use to install WordPress successfully with this script.

* WordPress < 4.7 needs PHP 7.0.3 or lower (or you get a warning)(Will be fixed in WP)
* WordPress < 3.9 needs PHP 5.3 or lower (or you get a fatal error)(missing MySQL extension)

If you don't want this script to fix PHP errors set the `REMOVE_ERRORS` [variable](#variables) in this script to false.
## Requirements

* rsync

To sync the `wp-content` folder between installations rsync is required. If it's not installed, right click the site name in the Local app and choose `Open Site SSH`.

```bash
# Update packages
apt-get update

# Install rsync
apt-get install -y rsync
```

## Installation
To install this script go to the website's /app folder

```bash
cd path/to/local/website/app
```

Download this script
```bash
curl -o wp-local-version.sh https://raw.githubusercontent.com/keesiemeijer/wp-local-version/master/wp-local-version.sh
```

And **edit the variables** in the `wp-local-version.sh` script to match your site ([see below](#variables)).

## Variables
Change the variables in the `wp-local-version.sh` file to match your site before installing new WordPress versions.

**Note** It's important to edit the `DOMAIN` and `database` variables otherwise you probably can't visit the site after installing a new WP version.

```bash
# =============================================================================
# Variables
# Edit these variables to match your site.
#
# Note: Don't use spaces around the equal sign when editing variables below.
# =============================================================================

# Domain name
readonly DOMAIN="yourwebsite.local"

# Database credentials
readonly DB_NAME="local"
readonly DB_USER="root"
readonly DB_PASS="root"

# Wordpress credentials
readonly WP_USER="admin"
readonly WP_PASS="password"

# Remove errors. Default true
readonly REMOVE_ERRORS=true

# Keep the current wp-content folder for this website when installing a new WP version.
# 
# If set to false you loose everything you've changed in the wp-content folder
readonly KEEP_WP_CONTENT=true

# Locale of WordPress install. Default empty string (en_US locale)
readonly LOCALE=''

# WordPress default version to be installed. Default: "latest"
# See the release archive: https://wordpress.org/download/release-archive/
#
# Use a version number or "latest"
WP_VERSION="latest"

# =============================================================================
#
# That's all, stop editing!
#
# =============================================================================
```


## Installing a new WP Version

**WARNING**: The database and WordPress directory (except `wp-content`) are **deleted** prior to installing a new version. If there are files outside of the `wp-content` folder you want to keep, you'll need to back them up before installing a new WP version with this script.

To install a new WP version follow these steps

1 - Right click the site name in the Local app and choose `Open Site SSH`.  
2 - Go to the `/app` folder

```bash
cd /app
```

3 - Install a new WP version. (Without a version number the latest WP version is installed)

```bash
bash wp-local-version.sh 4.4
```

If all went well it shows a message with instructions how to finish the install.
