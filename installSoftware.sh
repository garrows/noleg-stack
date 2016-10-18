#!/bin/bash
set -e
set -v

sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/mongodb.list
sudo apt-get update

# Install git, nginx, mongo, nodejs, forever and express
sudo apt-get install -y nginx git letsencrypt mongodb-10gen unzip build-essential

# Install node
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
sudo apt-get install -y nodejs
