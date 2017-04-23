#!/bin/bash

if [[ $# -lt 2 ]]
then
	echo "Usage: sudo ./setupBasicSite.sh example.com nodeport"
	exit
fi

DOMAIN=$1
NODEPORT=$2

set -e
set -v

GITDIR=/home/git/$DOMAIN.git
WEBDIR=/var/www/$DOMAIN
SERVICE=node-$DOMAIN

# Setup git repo
sudo mkdir -p $GITDIR
sudo git init --bare $GITDIR
sudo chown -R git:www-data $GITDIR

# Setup publish directories for node sites
sudo mkdir -p $WEBDIR
sudo chgrp -R www-data $WEBDIR
sudo chmod -R g+w $WEBDIR

# Setup git to publish a copy of the repository to /var/www/$DOMAIN/current every time a commit happens
cp post-receive.sh /tmp/post-receive
sed -i "s,%WEBDIR%,$WEBDIR," /tmp/post-receive
sed -i "s,%SERVICE%,$SERVICE," /tmp/post-receive
sudo mv /tmp/post-receive $GITDIR/hooks/post-receive
sudo chmod 755 $GITDIR/hooks/post-receive
sudo chown git:www-data $GITDIR/hooks/post-receive

# Setup upstart to keep node running
cp systemd.service /tmp/$SERVICE.conf
sed -i "s,%APPLICATION%,$DOMAIN," /tmp/$SERVICE.conf
sed -i "s,%NODEPORT%,$NODEPORT," /tmp/$SERVICE.conf
sed -i "s,%PATH%,$WEBDIR/current," /tmp/$SERVICE.conf
touch "$WEBDIR/environment_variables"
chmod 644 /tmp/$SERVICE.conf
sudo mv /tmp/$SERVICE.conf /etc/systemd/system/$SERVICE.service

# Setup lets encrypt
#letsencrypt certonly --webroot -w /var/www/freshplans.garrows.com/current/public/ -d freshplans.garrows.com
#sudo cp /etc/letsencrypt/live/freshplans.garrows.com/fullchain.pem /etc/nginx/freshplans.garrows.com.chained.pem
#sudo cp /etc/letsencrypt/live/freshplans.garrows.com/privkey.pem /etc/nginx/freshplans.garrows.com.private.pem

# Configure nginx to direct traffic to the node processes
cp nginx.conf /tmp/$DOMAIN
sed -i "s,%DOMAIN%,$DOMAIN," /tmp/$DOMAIN
sed -i "s,%NODEPORT%,$NODEPORT," /tmp/$DOMAIN
sudo mv /tmp/$DOMAIN /etc/nginx/sites-available/$DOMAIN
sudo ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/$DOMAIN
sudo service nginx restart
