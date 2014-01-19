#!/bin/bash

set -e
REV=`git rev-parse HEAD`
DIR=/var/www/$REV/
mkdir -p $DIR
echo "Checking out to $DIR"
GIT_WORK_TREE=$DIR git checkout -f
 
cd $DIR
cd www
npm install
cd ../blog
npm install
echo "Done installs"
 
if [ -d /var/www/current ]; then
  OLD_DIR=`readlink /var/www/current`
fi
 
echo "Linking $DIR"
ln -sfn $DIR /var/www/current
 
if [ -d /var/www/current ]; then
  echo "Removing old directory $OLD_DIR"
  rm -rf $OLD_DIR
fi



is_upstart_service_running(){
    status $1 | grep -q "^$1 start" > /dev/null
    return $?
}

does_upstart_service_exist(){
    status $1 | grep -q "^$1 Unknown" > /dev/null
    return $?
}


if is_upstart_service_running node-www
then
        echo "Stopping node-www"
        sudo stop node-www
fi
if ! does_upstart_service_exist node-www
then
        echo "Starting node-www"
        sudo start node-www
fi

if is_upstart_service_running node-blog
then
        echo "Stopping node-blog"
        sudo stop node-blog
fi
if ! does_upstart_service_exist node-blog
then
        echo "Starting node-blog"
        sudo start node-blog
fi

echo "Done"

