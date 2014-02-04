#!/bin/bash
set -e
set -v

##############################
# Replace this with your own #
##############################
DOMAIN=example.com

sudo apt-get update

# Install git, nginx, mongo, nodejs, forever and express
sudo apt-get install -y nginx
sudo nginx

sudo apt-get install -y git

sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/mongodb.list
sudo apt-get update
sudo apt-get install -y mongodb-10gen

sudo apt-get install -y python-software-properties python g++ make
sudo add-apt-repository -y ppa:chris-lea/node.js
sudo apt-get update
sudo apt-get install -y nodejs

sudo npm install -g forever express


# Download the config files
cd /tmp
git clone https://github.com/garrows/noleg-stack.git


# Create users for git and nodejs
sudo adduser --shell $(which git-shell) --gecos 'git version control' --disabled-password git
sudo usermod -a -G www-data git
sudo chsh -s /usr/bin/git-shell git

sudo adduser --gecos 'node daemon user' --disabled-password node-user
sudo usermod -a -G www-data node-user
sudo usermod -a -G git node-user


# Add ubuntu's user to the authorized keys for git
sudo mkdir -p /home/git/.ssh
sudo touch /home/git/.ssh/authorized_keys
sudo chmod 600 /home/git/.ssh/authorized_keys
sudo chmod 700 /home/git/.ssh
sudo chown -R git:git /home/git/

cat /home/ubuntu/.ssh/authorized_keys | sudo tee -a /home/git/.ssh/authorized_keys

ssh-keygen -t rsa -N '' -f /home/ubuntu/.ssh/id_rsa
cat /home/ubuntu/.ssh/id_rsa.pub | sudo tee -a /home/git/.ssh/authorized_keys


# Setup git server
sudo mkdir -p /opt/git/website.git
cd /opt/git/website.git
sudo git --bare init

sudo chown -R git:www-data /opt/git/website.git


# Clone empty repository
cd /tmp/
echo -e "Host $DOMAIN\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
echo -e "Host localhost\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
git clone git@localhost:/opt/git/website.git
# git clone git@$DOMAIN:/opt/git/website.git
cd website


# Create skelleton express site and commit it to the git server
express --force --sessions --css stylus --ejs www

echo "node_modules" > .gitignore
git add .
git commit -m "Initial commit"
git push origin master


# Setup publish directories for node sites
sudo mkdir -p /var/www
sudo chgrp -R www-data /var/www
sudo chmod -R g+w /var/www

# Make a static directory that wont be updated by git hooks
sudo mkdir -p /var/www/static
cd /var/www/static


# Install ghost to the static directory
cd /tmp
wget https://ghost.org/zip/ghost-0.4.1.zip
sudo apt-get install -y unzip
unzip ghost-0.4.1.zip -d blog
rm ghost-0.4.1.zip

# Modify ghost's config to point to http://example.com/blog
cat blog/config.example.js | sed -e "s/my-ghost-blog.com/$DOMAIN\/blog/g" > blog/config.js

# Move to static web directory and change ownership to node-user
sudo mv blog /var/www/static/blog
sudo chown -R node-user:www-data /var/www/static


# Get git to publish a copy of the repository to /var/www/current every time a commit happens
sudo cp /tmp/noleg-stack/post-receive.sh /opt/git/website.git/hooks/post-receive
sudo chmod 755 /opt/git/website.git/hooks/post-receive
sudo chown git:www-data /opt/git/website.git/hooks/post-receive


# Test the auto publish script
cd /tmp/website
touch README.md
git add README.md
git commit -m "Added readme to test auto publish"
git push


# Setup upstart to keep node running after reboots
cat /tmp/noleg-stack/upstart.conf | sed -e "s/%APPLICATION%/node-www/g" | sed -e "s/%PATH%/\/var\/www\/current\/www\/app.js/g" > node-www.conf

cat /tmp/noleg-stack/upstart.conf | sed -e "s/%APPLICATION%/node-blog/g" | sed -e "s/%PATH%/\/var\/www\/static\/blog\/index.js/g"> node-blog.conf

chmod 777 node-www.conf
chmod 777 node-blog.conf
sudo mv node-*.conf /etc/init/

# Setup the logging directories
sudo mkdir -p /var/log/node
sudo chown node-user:www-data /var/log/node


# Give the git user account root access so it can restart upstart daemons
echo "git ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/node-restart
sudo chmod 440 /etc/sudoers.d/node-restart

# Test starting the upstart services
sudo start node-www
sudo start node-blog


# Configure nginx to direct traffic to the two node processes
cat /tmp/noleg-stack/nginx.conf | sed -e "s/%APPLICATION%/$DOMAIN/g" | sed -e "s/%PORTWWW%/3000/g" | sed -e "s/%PORTBLOG%/2368/g" > $DOMAIN

sudo mv $DOMAIN /etc/nginx/sites-available/$DOMAIN

sudo ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/$DOMAIN

sudo service nginx restart
