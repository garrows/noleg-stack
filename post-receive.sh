#!/bin/bash

set -e

WEBDIR=%WEBDIR%
SERVICE=%SERVICE%

#Get latest commit
REV=`git rev-parse master`
CHECKOUTDIR=$WEBDIR/$REV/

OLD_DIR="Unknown"
if [ -d $WEBDIR/current ]; then
  OLD_DIR=`readlink $WEBDIR/current`
fi

if [ $OLD_DIR == $CHECKOUTDIR ]; then
    echo "WARNING: Master SHA hasn't changed. Aborting publish. $REV"
    exit 0
fi


mkdir -p $CHECKOUTDIR
echo "Checking out to $CHECKOUTDIR"
GIT_WORK_TREE=$CHECKOUTDIR git checkout -f master

cd $CHECKOUTDIR
echo "Attempting build"

if [ -a Makefile ]; then
  echo "Running make"
  make
fi

echo "NPM Installing"
npm install

echo "Done build"


echo "Linking $CHECKOUTDIR"
ln -sfn $CHECKOUTDIR $WEBDIR/current

if [ -d $OLD_DIR ]; then
  echo "Removing old directory $OLD_DIR"
  rm -rf $OLD_DIR
fi


is_systemd_service_running(){
    systemctl status $1 | grep -q "(running)" > /dev/null
    return $?
}

does_systemd_service_exist(){
    systemctl status $1 | grep -q "not-found" > /dev/null
    return $?
}

# Restart the website
if is_systemd_service_running $SERVICE
then
        echo "Stopping $SERVICE"
        sudo systemctl stop $SERVICE
fi
if ! does_systemd_service_exist $SERVICE
then
        echo "Starting $SERVICE"
        sudo systemctl start $SERVICE
fi

echo "Done"
