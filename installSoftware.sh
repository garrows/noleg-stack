#!/bin/bash
set -e
set -v

sudo apt-get update

# Install git, nginx, mongo, nodejs, forever and express
sudo apt-get install -y nginx

sudo apt-get install -y git

sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/mongodb.list
sudo apt-get update
sudo apt-get install -y mongodb-10gen

sudo apt-get install -y software-properties-common python-software-properties python g++ make
sudo add-apt-repository -y ppa:chris-lea/node.js
sudo apt-get update
sudo apt-get install -y nodejs
sudo apt-get install -y unzip

sudo npm install -g forever express
