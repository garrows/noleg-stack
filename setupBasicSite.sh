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

# Get git to publish a copy of the repository to /var/www/$DOMAIN/current every time a commit happens
cat post-receive.sh | sed -e "s/%WEBDIR%/$WEBDIR/g" | sed -e "s/%SERVICE%/$SERVICE/g" > /tmp/post-receive
sudo mv /tmp/post-receive $GITDIR/hooks/post-receive
sudo chmod 755 $GITDIR/hooks/post-receive
sudo chown git:www-data $GITDIR/hooks/post-receive

# Setup upstart to keep node running
cat /tmp/noleg-stack/upstart.conf | sed -e "s/%APPLICATION%/$DOMAIN/g" | sed -e "s/%NODEPORT%/$NODEPORT/g" | sed -e "s/%PATH%/$WEBDIR/g" > $SERVICE.conf
chmod 777 $SERVICE.conf
sudo mv $SERVICE.conf /etc/init/

# Configure nginx to direct traffic to the two node processes
cat nginx.conf | sed -e "s/%APPLICATION%/$DOMAIN/g" | sed -e "s/%NODEPORT%/$NODEPORT/g" > /tmp/$DOMAIN

sudo mv /tmp/$DOMAIN /etc/nginx/sites-available/$DOMAIN

sudo ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/$DOMAIN

sudo service nginx restart
