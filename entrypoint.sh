#!/bin/bash

catalina.sh start
adb devices
./wait-for-it.sh -t 30 "$DB_HOST:$DB_PORT"
if [ ! -f '/usr/local/tomcat/conf/Catalina/localhost/ROOT.xml' ]; then
    ./install.sh
fi
catalina.sh stop
sleep 30

catalina.sh run
