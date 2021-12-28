#!/bin/sh
#
# Headwind MDM installer script
# Tested on Ubuntu Linux 18.04 - 20.10, Ubuntu 20.04 is recommended
#
TOMCAT_DEPLOY_PATH="ROOT"
BASE_PATH=""
TOMCAT_USER='root'
REPOSITORY_BASE='https://h-mdm.com/files'
LOCATION="/usr/hmdm"
DEFAULT_SCRIPT_LOCATION="/usr/hmdm"
PROTOCOL=http
SQL_HOST=$DB_HOST
SQL_PORT=$DB_PORT
SQL_BASE=$DB_BASE
SQL_USER=$DB_USER
SQL_PASS=$DB_PASSWORD
CLIENT_VARIANT="os"
# CLIENT_VARIANT="master"
CLIENT_APK="hmdm-$CLIENT_VERSION-$CLIENT_VARIANT.apk"
LANGUAGE=fr
SERVER_WAR=$LOCATION/hmdm.war
BASE_DOMAIN='0.0.0.0'
PORT='8080'



echo
echo "File storage setup"
echo "=================="


# Create directories
if [ ! -d $LOCATION ]; then
    mkdir -p $LOCATION || exit 1
    chown $TOMCAT_USER:$TOMCAT_USER $LOCATION || exit 1
fi

if [ ! -d $LOCATION/files ]; then
    mkdir $LOCATION/files
    chown $TOMCAT_USER:$TOMCAT_USER $LOCATION/files || exit 1
fi

if [ ! -d $LOCATION/plugins ]; then
    mkdir $LOCATION/plugins
    chown $TOMCAT_USER:$TOMCAT_USER $LOCATION/plugins || exit 1
fi

if [ ! -d $LOCATION/logs ]; then
    mkdir $LOCATION/logs
    chown $TOMCAT_USER:$TOMCAT_USER $LOCATION/logs || exit 1
fi

INSTALL_FLAG_FILE="$LOCATION/hmdm_install_flag"




# Logger configuration
cat ./install/log4j_template.xml | sed "s|_BASE_DIRECTORY_|$LOCATION|g" > $LOCATION/log4j-hmdm.xml
chown $TOMCAT_USER:$TOMCAT_USER $LOCATION/log4j-hmdm.xml

echo
echo "Please choose the directory where supply scripts will be located."
echo
if [ ! -d $SCRIPT_LOCATION ]; then
    mkdir -p $SCRIPT_LOCATION || exit 1
fi


echo
echo "PostgreSQL database setup"
echo "========================="
echo "Rest Sql migration"
echo

PSQL_CONNSTRING="postgresql://$SQL_USER:$SQL_PASS@$SQL_HOST:$SQL_PORT/$SQL_BASE"


# Check the PostgreSQL access
echo "SELECT 1" | psql $PSQL_CONNSTRING > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
    echo "Failed to connect to $SQL_HOST:$SQL_PORT/$SQL_BASE as $SQL_USER!"
    echo "Please make sure you've created the database!"
    exit 1
fi

TABLE_EXISTS=$(echo "\dt users" | psql $PSQL_CONNSTRING 2>&1 | grep public)
if [ -n "$TABLE_EXISTS" ]; then
    echo "The database is already setup."
    echo "To re-deploy Headwind MDM, the database needs to be cleared."
    echo "Clear the database? ALL DATA WILL BE LOST!"
    if [ 1 ]; then
        echo "DROP TABLE IF EXISTS applicationfilestocopytemp, applications, applicationversions, applicationversionstemp, configurationapplicationparameters, configurationapplications, configurationapplicationsettings, configurationfiles, configurations, customers, databasechangelog, databasechangeloglock, deviceapplicationsettings, devicegroups, devices, devicestatuses, groups, icons, pendingpushes, permissions, plugin_apuppet_data, plugin_apuppet_settings, plugin_audit_log, plugin_deviceinfo_deviceparams, plugin_deviceinfo_deviceparams_device, plugin_deviceinfo_deviceparams_gps, plugin_deviceinfo_deviceparams_mobile, plugin_deviceinfo_deviceparams_mobile2, plugin_deviceinfo_deviceparams_wifi, plugin_deviceinfo_settings, plugin_devicelocations_history, plugin_devicelocations_latest, plugin_devicelocations_settings, plugin_devicelog_log, plugin_devicelog_setting_rule_devices, plugin_devicelog_settings, plugin_devicelog_settings_rules, plugin_devicereset_status, plugin_knox_rules, plugin_messaging_messages, plugin_openvpn_defaults, plugin_photo_photo, plugin_photo_photo_places, plugin_photo_places, plugin_photo_settings, plugins, pluginsdisabled, pushmessages, settings, trialkey, uploadedfiles, userconfigurationaccess, userdevicegroupsaccess, userhints, userhinttypes, userrolepermissions, userroles, userrolesettings, users" |  psql $PSQL_CONNSTRING >/dev/null 2>&1
	echo "Database has been cleared."
    else
        echo "Headwind MDM installation aborted"
	exit 1
    fi
fi
echo "========================="
echo

echo
echo "Web application setup"
echo "====================="
echo "Headwind MDM requires access from Internet"
echo "Please assign a public domain name to this server"
echo

if [ -z $PROTOCOL ]; then
        PROTOCOL=$DEFAULT_PROTOCOL
fi


if [ -z $TOMCAT_HOST ]; then
        TOMCAT_HOST=$DEFAULT_TOMCAT_HOST
fi





if [ ! -z "$PORT" ]; then
    BASE_HOST="$BASE_DOMAIN:$PORT"
else
    BASE_HOST="$BASE_DOMAIN"
fi

echo
echo "Ready to install!"
echo "Location on server: $LOCATION"
echo "URL: $PROTOCOL://$BASE_HOST$BASE_PATH"


# Prepare the XML config
if [ ! -f ./install/context_template.xml ]; then
    echo "ERROR: Missing ./install/context_template.xml!"
    echo "The package seems to be corrupted!"
    exit 1
fi

# Removing old application if required
if [ -d $TOMCAT_HOME/webapps/$TOMCAT_DEPLOY_PATH ]; then
    rm -rf $TOMCAT_HOME/webapps/$TOMCAT_DEPLOY_PATH > /dev/null 2>&1
    rm -f $TOMCAT_HOME/webapps/$TOMCAT_DEPLOY_PATH.war > /dev/null 2>&1
    echo "Waiting for undeploying the previous version"
    for i in {1..10}; do
        echo -n "."
        sleep 1
    done
    echo
fi

TOMCAT_CONFIG_PATH=$TOMCAT_HOME/conf/$TOMCAT_ENGINE/$TOMCAT_HOST
if [ ! -d $TOMCAT_CONFIG_PATH ]; then
    mkdir -p $TOMCAT_CONFIG_PATH || exit 1
    chown root:$TOMCAT_USER $TOMCAT_CONFIG_PATH
    chmod 755 $TOMCAT_CONFIG_PATH
fi



cat /usr/hmdm/install/context_template.xml | sed "s|_SQL_HOST_|$SQL_HOST|g; s|_SQL_PORT_|$SQL_PORT|g; s|_SQL_BASE_|$SQL_BASE|g; s|_SQL_USER_|$SQL_USER|g; s|_SQL_PASS_|$SQL_PASS|g; s|_BASE_DIRECTORY_|$LOCATION|g; s|_PROTOCOL_|$PROTOCOL|g; s|_BASE_HOST_|$BASE_HOST|g; s|_BASE_DOMAIN_|$BASE_DOMAIN|g; s|_BASE_PATH_|$BASE_PATH|g; s|_INSTALL_FLAG_|$INSTALL_FLAG_FILE|g" > $TOMCAT_CONFIG_PATH/$TOMCAT_DEPLOY_PATH.xml
if [ "$?" -ne 0 ]; then
    echo "Failed to create a Tomcat config file $TOMCAT_CONFIG_PATH/$TOMCAT_DEPLOY_PATH.xml!"
    exit 1
fi
echo "Tomcat config file created: $TOMCAT_CONFIG_PATH/$TOMCAT_DEPLOY_PATH.xml"
chmod 644 $TOMCAT_CONFIG_PATH/$TOMCAT_DEPLOY_PATH.xml


echo "Deploying $SERVER_WAR to Tomcat: $TOMCAT_HOME/webapps/$TOMCAT_DEPLOY_PATH.war"
rm -f $INSTALL_FLAG_FILE > /dev/null 2>&1
cp $SERVER_WAR $TOMCAT_HOME/webapps/$TOMCAT_DEPLOY_PATH.war
chmod 644 $TOMCAT_HOME/webapps/$TOMCAT_DEPLOY_PATH.war



# Waiting until the end of deployment
SUCCESSFUL_DEPLOY=0
# shellcheck disable=SC2034

for i in $(seq 1 1 1200); do
    if [ -f $INSTALL_FLAG_FILE ]; then
        # shellcheck disable=SC2046
        FLAG=$(cat $INSTALL_FLAG_FILE);
        if [ "$FLAG" = 'OK' ]; then
            SUCCESSFUL_DEPLOY=1
        else
            SUCCESSFUL_DEPLOY=0
        fi
        break
    fi
    echo -n "."
    sleep 1s
done
echo
rm -f $INSTALL_FLAG_FILE > /dev/null 2>&1
if [ $SUCCESSFUL_DEPLOY -ne 1 ]; then
    echo "ERROR: failed to deploy WAR file!"
    echo "Please check $TOMCAT_HOME/logs/catalina.out for details."
    exit 1
fi
echo "Deployment successful, initializing the database..."



# Download required files
FILES=$(echo "SELECT url FROM applicationversions WHERE url IS NOT NULL" | psql $PSQL_CONNSTRING 2>/dev/null | tail -n +3 | head -n -2)
CURRENT_DIR=$(pwd)
cd $LOCATION/files
for FILE in $FILES; do
    echo "Downloading $FILE..."
wget $FILE
done
chown $TOMCAT_USER:$TOMCAT_USER *
echo "UPDATE applicationversions SET url=REPLACE(url, 'https://h-mdm.com', '$PROTOCOL://$BASE_HOST$BASE_PATH') WHERE url IS NOT NULL" | psql $PSQL_CONNSTRING >/dev/null 2>&1
cd $CURRENT_DIR



echo
echo "======================================"
echo "Headwind MDM installation is completed!"
echo "To access your web panel, open in the web browser:"
echo "$PROTOCOL://$BASE_HOST$BASE_PATH"
echo "Login: admin:admin"
echo "======================================"
echo




# Migrassation des donnnée
echo "PostgreSQL database setup"
echo "========================="
echo "Make sure you've installed PostgreSQL and created the database."
echo "If you didn't create a database yet, please click Ctrl-C to break,"
echo "then execute the following commands:"
echo "-------------------------"
echo "su postgres"
echo "psql"
echo "CREATE USER hmdm WITH PASSWORD 'topsecret';"
echo "CREATE DATABASE hmdm WITH OWNER=hmdm;"
echo "\q"
echo "exit"
echo "-------------------------"



PSQL_CONNSTRING="postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_BASE"

# Check the PostgreSQL access
echo "SELECT 1" | psql $PSQL_CONNSTRING > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
    echo "Failed to connect to $SQL_HOST:$DB_PORT/$DB_BASE as $SQL_USER!"
    echo "Please make sure you've created the database!"
    exit 1
fi



# Initialize database
cat /usr/hmdm/install/sql/hmdm_init.$LANGUAGE.sql | sed "s|_HMDM_BASE_|$LOCATION|g; s|_HMDM_VERSION_|$CLIENT_VERSION|g; s|_HMDM_APK_|$CLIENT_APK|g" > $TEMP_SQL_FILE
cat $TEMP_SQL_FILE | psql $PSQL_CONNSTRING > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
    echo "ERROR: failed to execute SQL script!"
    echo "See $TEMP_SQL_FILE for details."
    exit 1
fi
rm -f $TEMP_SQL_FILE > /dev/null 2>&1


