#!/bin/bash
set -e
set -v
 
DOMAIN=example.com
 
sudo apt-get update
 
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

cd /tmp
git clone https://github.com/garrows/noleg-stack.git
 
sudo adduser --shell $(which git-shell) --gecos 'git version control' --disabled-password git
sudo usermod -a -G www-data git
sudo chsh -s /usr/bin/git-shell git
 
sudo mkdir -p /home/git/.ssh
sudo touch /home/git/.ssh/authorized_keys
sudo chmod 600 /home/git/.ssh/authorized_keys
sudo chmod 700 /home/git/.ssh
sudo chown -R git:git /home/git/
 
cat /home/ubuntu/.ssh/authorized_keys | sudo tee -a /home/git/.ssh/authorized_keys
 
ssh-keygen -t rsa -N '' -f /home/ubuntu/.ssh/id_rsa
cat /home/ubuntu/.ssh/id_rsa.pub | sudo tee -a /home/git/.ssh/authorized_keys
 
sudo mkdir -p /opt/git/website.git
cd /opt/git/website.git
sudo git --bare init
 
sudo chown -R git:www-data /opt/git/website.git
 
 
cd /tmp/
echo -e "Host $DOMAIN\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
git clone git@$DOMAIN:/opt/git/website.git
cd website
 
express --force --sessions --css stylus --ejs www
 
echo "node_modules" > .gitignore
git add .
git commit -m "Initial commit"
git push origin master
 
cd /tmp/website
wget https://ghost.org/zip/ghost-0.4.0.zip
sudo apt-get install unzip
unzip ghost-0.4.0.zip -d blog
rm ghost-0.4.0.zip
 
git add .
git commit -m "Added blog"
git push origin master
 
sudo mkdir -p /opt/ghostdb
sudo cp -R /tmp/website/blog/content /opt/ghostdb
sudo chown -R git:www-data /opt/ghostdb
sudo chmod -R 770 /opt/ghostdb
cd /tmp/website/blog
cat config.example.js | sed -e "s/__dirname/\'\/opt\/ghostdb\'/g" | sed -e "s/my-ghost-blog.com/$DOMAIN\/blog/g" > config.js
 
git add config.js
git commit -m "Updated ghost config so the database is not lost"
git push origin master
 
sudo mkdir -p /var/www
sudo chgrp -R www-data /var/www
sudo chmod -R g+w /var/www
 
sudo touch /opt/git/website.git/hooks/post-receive
sudo chmod 777 /opt/git/website.git/hooks/post-receive

 
sudo cp /tmp/noleg-stack/post-receive.sh /opt/git/website.git/hooks/post-receive
sudo chmod 755 /opt/git/website.git/hooks/post-receive
sudo chown git:www-data /opt/git/website.git/hooks/post-receive
 
 
cd /tmp/website
touch README.md
git add README.md
git commit -m "Added readme to test auto publish"
git push
 
cat /tmp/noleg-stack/upstart.conf | sed -e "s/%APPLICATION%/node-www/g" | sed -e "s/%PATH%/\/var\/www\/current\/www\/app.js/g" > node-www.conf
 
cat /tmp/noleg-stack/upstart.conf | sed -e "s/%APPLICATION%/node-blog/g" | sed -e "s/%PATH%/\/var\/www\/current\/blog\/index.js/g"> node-blog.conf
 
chmod 777 node-www.conf
chmod 777 node-blog.conf
sudo mv node-*.conf /etc/init/
 
sudo adduser --gecos 'node daemon user' --disabled-password nodeuser
sudo usermod -a -G www-data nodeuser
sudo usermod -a -G git nodeuser
 
sudo mkdir -p /var/log/node
sudo chown nodeuser:www-data /var/log/node

echo "git ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/node-restart
sudo chmod 440 /etc/sudoers.d/node-restart
 
sudo start node-www
sudo start node-blog
 
 
cat /tmp/noleg-stack/nginx.conf | sed -e "s/%APPLICATION%/$DOMAIN/g" | sed -e "s/%PORTWWW%/3000/g" | sed -e "s/%PORTBLOG%/2368/g" > $DOMAIN
 
sudo mv $DOMAIN /etc/nginx/sites-available/$DOMAIN
 
sudo ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/$DOMAIN
 
sudo service nginx restart