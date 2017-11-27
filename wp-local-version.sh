#!/usr/bin/env bash

# =============================================================================
# WP Local Version
#
# Version 2.0.0
#
# By keesiemeijer
# https://github.com/keesiemeijer/wp-local-version
#
# This bash script lets you install any WordPress version in the Local by Freewheel app (without getting PHP errors).
#
# ********* Features *********
#
#     WP-CLI is used to install WP versions > 3.5.2
#     Older WP versions are installed by this script.
#     Ability to keep the wp-content folder between versions.
#
# ********* PHP Version *********
#
# WordPress is not compatible with all PHP versions (in the Local app).
# Here's an overview of what PHP version you'll have to use for WordPress to be installed successfully.
#     WordPress < 4.7 needs PHP 5.6 or lower (or you get a warning)
#     WordPress < 3.9 needs PHP 5.3 or lower (or you get a fatal error)
#
# ********* Requirements *********
#
#     rsync
#
# To sync the wp-content folder between installations rsync is required..
# If it's not installed already, right click the site and choose Open Site SSH.
# Go to the /app folder
#  	cd /app
#
# Install rsync
#   apt-get install -y rsync
#
# ********* Warning !!! *********
#
# The database and directory for the WordPress install (except wp-content) are deleted prior to installing.
#     Back up files outside wp-content (if you don't want them deleted) before installing a new version.
#
# This script fixes (fatal) errors for earlier versions (WP < 2.0) by hacking core files.
# This script hides errors by setting error_reporting off in:
#     wp-config.php (WP < 3.5.2)
#     wp-settings.php (WP < 3.0.0)
#
# ********* Installation *********
# To install this script go to the website's /app folder
#     cd path/to/local/website/app
#
# And download this script
#     curl -o wp-local-version.sh https://raw.githubusercontent.com/keesiemeijer/wp-local-version/master/wp-local-version.sh
#
# Finally, edit the variables in this script to match your site.
#
# **Note** It's important to edit the DOMAIN variable 
#          otherwise you can't visit the site after installing a new WP version. 
#
# ********* Installing a new WP Version *********
# Please read the Warning section above before installing new WP versions.
#
# To install a new WP version follow the following steps
#     1 Right click the site and choose Open Site SSH.
#     2 Go to the /app folder
#         cd /app
#     3 Install a new WP version. (Without a version number the latest WP version is installed)
#         bash wp-local-version.sh 4.4
#
# If all went well it shows a message with instructions how to finish the install.
#
# ********* License *********
#
# License: GPL-2.0+
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version. You may NOT assume that you can use any other version of the GPL. 
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# =============================================================================


# =============================================================================
# Variables
#
# Note: Don't use spaces around the equal sign when editing variables below.
# =============================================================================

# Domain name
readonly DOMAIN="yourwebsite.local"


# WordPress version to be installed. Default: latest version
# See the release archive: https://wordpress.org/download/release-archive/
#
# Use a version number or "latest"
WP_VERSION="latest"

# Remove errors. Default true
readonly REMOVE_ERRORS=false

# Keep the current wp-content folder for this website
# If set to false you loose everything you changed in the wp-content folder
readonly KEEP_WP_CONTENT=false

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

# current path
readonly CURRENT_PATH=$(pwd)

# DocumentRoot dir in .conf file (if server is Apache)
readonly CURRENT_DIR="${PWD##*/}"

# path to the WordPress install for the developer reference website
readonly INSTALL_PATH="$CURRENT_PATH/public"

if [ $# == 1 ]; then
	WP_VERSION=$1
fi

function is_file() {
	local file=$1
	[[ -f $file ]]
}

function is_dir() {
	local dir=$1
	[[ -d $dir ]]
}

printf "\nStart Setup '%s'...\n" "$DOMAIN"

if [[ "$KEEP_WP_CONTENT" = true ]]; then

	# apt-get install -y wget subversion curl rsync
	# Check if rsync is installed
	command -v rsync >/dev/null 2>&1 || { echo "Abort script. Please install rsync if you want to keep the wp-content directory from being removed (when updating a WP version)." >&2; exit 1; }
fi


# =============================================================================
# Creating database and 'public' directory
# =============================================================================

printf "Resetting database '%s'...\n" "$DB_NAME"
mysql -u root --password=root -e "DROP DATABASE IF EXISTS \`$DB_NAME\`" 2>/dev/null
mysql -u root --password=root -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`" 2>/dev/null
mysql -u root --password=root -e "GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO $DB_USER@localhost IDENTIFIED BY '$DB_PASS';" 2>/dev/null


printf "Creating directory %s...\n" "$INSTALL_PATH"
if ! is_dir "$INSTALL_PATH"; then
	mkdir "$INSTALL_PATH"
else 
	if is_dir "$INSTALL_PATH/wp-content" && [[ "$KEEP_WP_CONTENT" = true ]]; then
		printf "Backing up wp-content directory in  %s...\n" "$CURRENT_PATH/tmp-wp-content"
		if is_dir "$CURRENT_PATH/tmp-wp-content"; then
			rm -rf "$CURRENT_PATH/tmp-wp-content"
			mv "$INSTALL_PATH/wp-content" "$CURRENT_PATH/tmp-wp-content"
		else
			cp -rf "$INSTALL_PATH/wp-content" "$CURRENT_PATH/tmp-wp-content"
		fi
	fi
	rm -rf "$INSTALL_PATH"
	mkdir "$INSTALL_PATH"
fi

cd "$INSTALL_PATH" || exit

# =============================================================================
# Check Network Detection
#
# Make an HTTP request to google.com to determine if outside access is available
# to us. If 3 attempts with a timeout of 5 seconds are not successful, then we'll
# skip a few things further in provisioning rather than create a bunch of errors.
# =============================================================================
printf "Checking network connection...\n"
if ping -c 3 --linger=5 8.8.8.8 >> /dev/null 2>&1; then
	printf "Network connection detected...\n"
	printf "Downloading WordPress %s in %s...\n" "$WP_VERSION" "$INSTALL_PATH"
else
	printf "No network connection detected. ...\n"
	printf "Trying to get WordPress %s from cache...\n" "$WP_VERSION"
fi

if [[ "$WP_VERSION" = "latest" ]]; then
	wp core download --allow-root --force 2> /dev/null
	if is_file "$INSTALL_PATH/wp-includes/version.php"; then
		if grep -q "wp_version = " "$INSTALL_PATH/wp-includes/version.php"; then
			WP_VERSION=$(grep "wp_version = " "$INSTALL_PATH/wp-includes/version.php"|awk -F\' '{print $2}')
		fi
	fi
else
	wp core download --version="$WP_VERSION" --force --allow-root 2> /dev/null
fi

# Check if WordPress was downloaded
if ! is_file "$INSTALL_PATH/wp-config-sample.php"; then
	printf "Could not install WordPress. ...\n"
	printf "Make sure you are connected to the internet. ...\n"
	exit
fi

readonly TITLE="Wordpress $WP_VERSION"
readonly WP_VERSION="$WP_VERSION"

# =============================================================================
# Installing WordPress
# =============================================================================

finished=''
config_error=$(wp core config --dbname=$DB_NAME --dbuser=$DB_USER --dbpass=$DB_PASS --allow-root 2>&1 >/dev/null)

if [[ ! "$config_error" ]]; then
	# WP >= 3.5.2

	wp core install --url="$DOMAIN" --title="$TITLE" --admin_user="$WP_USER" --admin_password="$WP_PASS" --admin_email=demo@example.com --allow-root
	finished="Visit $DOMAIN/wp-admin Username: admin, Password: password"
else
	# WP < 3.5.2

	config_file="wp-config-sample.php"
	finished="Visit $DOMAIN/readme.html and follow the install instructions"

	if is_file "$INSTALL_PATH/$config_file"; then

		printf "Renaming wp-config-sample.php \n"
		cp "$INSTALL_PATH/wp-config-sample.php" "$INSTALL_PATH/wp-config.php"	

		if is_file "$INSTALL_PATH/wp-config.php"; then
			config_file="wp-config.php"
		fi	

		if [[ "$REMOVE_ERRORS" = true ]]; then
			# SRSLY Don't you dare show me any errors.
			sed -i -e "s/require_once(ABSPATH.'wp-settings.php');/error_reporting( 0 );\nrequire_once(ABSPATH.'wp-settings.php');\nerror_reporting( 0 );/g" "$INSTALL_PATH/$config_file"
			sed -i -e "s/require_once(ABSPATH . 'wp-settings.php');/error_reporting( 0 );\nrequire_once(ABSPATH . 'wp-settings.php');\nerror_reporting( 0 );/g" "$INSTALL_PATH/$config_file"
			if is_file "$INSTALL_PATH/wp-settings.php"; then
				sed -i -e "s/error_reporting(E_ALL ^ E_NOTICE);/error_reporting( 0 );/g" "$INSTALL_PATH/wp-settings.php"
				sed -i -e "s/error_reporting(E_ALL ^ E_NOTICE ^ E_USER_NOTICE);/error_reporting( 0 );/g" "$INSTALL_PATH/wp-settings.php"
				# Database errors
				sed -i -e "s/\$wpdb->show_errors();/\$wpdb->hide_errors();/g" "$INSTALL_PATH/wp-settings.php"
			fi
		fi
	fi	

	# WordPress 0.71-gold
	if is_file "$INSTALL_PATH/b2config.php"; then

		config_file="b2config.php"
		sed -i -e "s/http:\/\/example.com/http:\/\/$DOMAIN/g" "$INSTALL_PATH/$config_file"

		if [[ "$REMOVE_ERRORS" = true ]]; then
			printf "\n<?php error_reporting( 0 ); ?>\n" >> "$INSTALL_PATH/$config_file"
		fi
	fi

	if is_file "$INSTALL_PATH/$config_file"; then

		echo "Adding database credentials in $INSTALL_PATH/$config_file"

		sed -i -e "s/database_name_here/$DB_NAME/g" "$INSTALL_PATH/$config_file"
		sed -i -e "s/username_here/$DB_USER/g" "$INSTALL_PATH/$config_file"
		sed -i -e "s/password_here/$DB_PASS/g" "$INSTALL_PATH/$config_file"
		sed -i -e "s/define('DB_NAME', 'wordpress');/define('DB_NAME', '$DB_NAME');/g" "$INSTALL_PATH/$config_file"
		sed -i -e "s/define('DB_USER', 'username');/define('DB_USER', '$DB_USER');/g" "$INSTALL_PATH/$config_file"
		sed -i -e "s/define('DB_PASSWORD', 'password');/define('DB_PASSWORD', '$DB_PASS');/g" "$INSTALL_PATH/$config_file"
		sed -i -e "s/define('DB_NAME', 'putyourdbnamehere');/define('DB_NAME', '$DB_NAME');/g" "$INSTALL_PATH/$config_file"
		sed -i -e "s/define('DB_USER', 'usernamehere');/define('DB_USER', '$DB_USER');/g" "$INSTALL_PATH/$config_file"
		sed -i -e "s/define('DB_PASSWORD', 'yourpasswordhere');/define('DB_PASSWORD', '$DB_PASS');/g" "$INSTALL_PATH/$config_file"
		sed -i -e "s/define('DB_NAME', 'b2');/define('DB_NAME', '$DB_NAME');/g" "$INSTALL_PATH/$config_file"
		sed -i -e "s/define('DB_USER', 'user');/define('DB_USER', '$DB_USER');/g" "$INSTALL_PATH/$config_file"
		sed -i -e "s/define('DB_PASSWORD', 'pass');/define('DB_PASSWORD', '$DB_PASS');/g" "$INSTALL_PATH/$config_file"
	fi
fi

if [[ "$KEEP_WP_CONTENT" = true ]]; then
	if is_dir "$INSTALL_PATH/wp-content" && is_dir "$CURRENT_PATH/tmp-wp-content"; then
		printf "synchronizing wp-content directory. ...\n"
		rsync --ignore-times -r "$CURRENT_PATH/tmp-wp-content/" "$INSTALL_PATH/wp-content"
	fi
fi

# =============================================================================
# Removing Errors
# =============================================================================

if [[ "$REMOVE_ERRORS" = true && "$config_error" ]]; then
	echo "Removing errors"

	# Blank admin screen WP version 3.3.*
	if [[ ${WP_VERSION:0:3} == "3.3" ]]; then
		if is_file "$INSTALL_PATH/wp-admin/includes/screen.php"; then
			sed -i -e "s/echo self\:\:\$this->_help_sidebar;/echo \$this->_help_sidebar;/g" "$INSTALL_PATH/wp-admin/includes/screen.php"
		fi
	fi

	# Remove errors for versions 0.* and 1.* (error with PHP 5 and higher)
	if [[ ${WP_VERSION:0:1} == "1" || ${WP_VERSION:0:1} == "0" ]]; then

		# WP version 0.71-gold (error with PHP 5.3.0 and higher)
		# Call-time pass-by-reference has been deprecated
		if is_file "$INSTALL_PATH/b2-include/b2template.functions.php"; then
			sed -i -e 's/\&\$/\$/g' "$INSTALL_PATH/b2-include/b2template.functions.php"
		fi

		# Blank Step 3 for the install process
		# Cannot use object of type stdClass as array (error with PHP 5 and higher)
		if is_file "$INSTALL_PATH/wp-admin/upgrade-functions.php" ; then
			sed -i -e "s/res\[0\]\['Type'\]/res\[0\]->Type/g" "$INSTALL_PATH/wp-admin/upgrade-functions.php"
		fi


		find "$INSTALL_PATH" ! -name "$(printf "*\n*")" -name "*.php" > tmp
		while IFS= read -r file
		do
			sed -i -e "s/\$HTTP_GET_VARS/\$_GET/g" "$file"
			sed -i -e "s/\$HTTP_POST_VARS/\$_POST/g" "$file"
			sed -i -e "s/\$HTTP_SERVER_VARS/\$_SERVER/g" "$file"
			sed -i -e "s/\$HTTP_COOKIE_VARS/\$_COOKIE/g" "$file"
		done < tmp
		rm tmp
	fi
fi

printf "\nFinished Setup %s with version: %s!\n" "$DOMAIN" "$WP_VERSION"
echo "$finished"
echo ""