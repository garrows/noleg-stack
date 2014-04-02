#!/bin/bash

set -e

WEBDIR=%WEBDIR%
SERVICE=%SERVICE%

#Get latest commit
REV=`git rev-parse HEAD`
CHECKOUTDIR=$WEBDIR/$REV/

mkdir -p $CHECKOUTDIR
echo "Checking out to $CHECKOUTDIR"
GIT_WORK_TREE=$CHECKOUTDIR git checkout -f
 
cd $CHECKOUTDIR
echo "Attempting build"

if [ -a Makefile ]; then
  echo "Running make"
  make
fi

if [ -a FILE ]; then
  echo "NPM Installing"
  npm install
fi

echo "Done build"
 
if [ -d $WEBDIR/current ]; then
  OLD_DIR=`readlink $WEBDIR/current`
fi
 
echo "Linking $CHECKOUTDIR"
ln -sfn $CHECKOUTDIR $WEBDIR/current
 
if [ -d $OLD_DIR ]; then
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

# Restart the website
if is_upstart_service_running $SERVICE
then
        echo "Stopping $SERVICE"
        sudo stop $SERVICE
fi
if ! does_upstart_service_exist $SERVICE
then
        echo "Starting $SERVICE"
        sudo start $SERVICE
fi

echo "Done"

