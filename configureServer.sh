#!/bin/bash
set -e
set -v


# Create users for git and nodejs
sudo adduser --shell $(which git-shell) --gecos 'git version control' --disabled-password git
sudo usermod -a -G www-data git
sudo chsh -s /usr/bin/git-shell git

sudo adduser --gecos 'node daemon user' --disabled-password node-user
sudo usermod -a -G www-data node-user
sudo usermod -a -G git node-user


# Add user's to the authorized keys for git
sudo mkdir -p /home/git/.ssh
sudo touch /home/git/.ssh/authorized_keys
sudo chmod 600 /home/git/.ssh/authorized_keys
sudo chmod 700 /home/git/.ssh
sudo chown -R git:git /home/git/

cat ~/.ssh/authorized_keys | sudo tee -a /home/git/.ssh/authorized_keys

ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub | sudo tee -a /home/git/.ssh/authorized_keys

# Setup publish directories for node sites
sudo mkdir -p /var/www
sudo chgrp -R www-data /var/www
sudo chmod -R g+w /var/www

# Setup the logging directories
sudo mkdir -p /var/log/node
sudo chown node-user:www-data /var/log/node

# Give the git user account root access so it can restart upstart daemons
echo "git ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/node-restart
sudo chmod 440 /etc/sudoers.d/node-restart
