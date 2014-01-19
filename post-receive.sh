#!/bin/bash

set -e
REV=\`git rev-parse HEAD\`
DIR=/var/www/\$REV/
mkdir -p \$DIR
echo "Checking out to \$DIR"
GIT_WORK_TREE=\$DIR git checkout -f
 
cd \$DIR
cd www
npm install
cd ../blog
npm install
echo "Done installs"
 
if [ -d /var/www/current ]; then
  OLD_DIR=\`readlink /var/www/current\`
fi
 
echo "Linking \$DIR"
ln -sfn \$DIR /var/www/current
 
if [ -d /var/www/current ]; then
  echo "Removing old directory \$OLD_DIR"
  rm -rf \$OLD_DIR
fi