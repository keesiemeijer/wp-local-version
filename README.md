# WP Local Version

Version 2.0.0

This bash script lets you install any WordPress version in the Local by Freewheel app (without getting PHP errors).

Features:

* Ability to keep the `wp-content` folder between versions.
* WP-CLI is used to install WP versions > 3.5.2
* Older WP versions are installed by this script.
* Fatal errors are removed by hacking WP core files for WP versions < 2.0
* Errors are hidden by setting error_reporting off in:
    * wp-config.php (WP < 3.5.2)
    * wp-settings.php (WP < 3.0.0)

## PHP compatibility

WordPress is not compatible with all PHP versions (in the Local app). Here's an overview of what PHP version you'll have to use for WordPress to be installed successfully.

* WordPress < 4.7 needs PHP 5.6 or lower (or you get a warning)
* WordPress < 3.9 needs PHP 5.3 or lower (or you get a fatal error)

You can set the PHP version in the Local app

## Requirements

* rsync

To sync the wp-content folder between installations rsync is required. If it's not installed already, right click the site and choose Open Site SSH.

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

And download this script
```bash
curl -o wp-local-version.sh https://raw.githubusercontent.com/keesiemeijer/wp-local-version/master/wp-local-version.sh
```

Finally, edit the variables in this script to match your site.

**Note** It's important to edit the `DOMAIN` variable otherwise you can't visit the site after installing a new WP version.

```bash
# =============================================================================
# Variables
# Edit these variables to match your site.
#
# Note: Don't use spaces around the equal sign when editing variables below.
# =============================================================================

# Domain name
readonly DOMAIN="yourwebsite.local"

# WordPress default version to be installed. Default: "latest"
# See the release archive: https://wordpress.org/download/release-archive/
#
# Use a version number or "latest"
WP_VERSION="latest"

# Remove errors. Default true
readonly REMOVE_ERRORS=true

# Keep the current wp-content folder for this website when installing a new WP version.
# 
# If set to false you loose everything you've changed in the wp-content folder
readonly KEEP_WP_CONTENT=true

# Database credentials
readonly DB_NAME="wp-local-version"
readonly DB_USER="wp"
readonly DB_PASS="wp"

# Wordpress credentials
readonly WP_USER="admin"
readonly WP_PASS="password"

# =============================================================================
#
# That's all, stop editing!
#
# =============================================================================
```


## Installing a new WP Version

**WARNING**: The database and WordPress directory (except `wp-content`) are **deleted** prior to installing a new version. If there are files outside of the `wp-content` folder you want to keep, you'll need to back them up before installing a new WP version with this script.

To install a new WP version follow the following steps
1 - Right click the site and choose Open Site SSH.
2 - Go to the /app folder

```bash
cd /app
```

3 Install a new WP version. (Without a version number the latest WP version is installed)

```bash
bash wp-local-version.sh 4.4
```

If all went well it shows a message with instructions how to finish the install.
