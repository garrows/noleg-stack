The NOLEG (Node, mOngo, Linux (E)nginx Git) Stack
=================================================

This post explains the NOLEG stack and provides a script that will get you running with 2 node sites, running securely on a linux server behind nginx while being a git server with hooks for deploying your site every time you commit to your private repository all within 10 minutes (some assumptions made). 


Use the Script
==============

If you want to get started real fast, start your Ubuntu server and run setup.sh on it changing the DOMAIN setting to what ever domain you are using. You should be able to go to http://www.example.com and http://www.example.com/blog and see 2 different sites along with having your very own git server.

All you need to do is run the following commands on a fresh server (replace your-domain-here.com with your domain (dont include the www)) and you are all set.

```sh
sudo apt-get install -y git
git clone https://github.com/garrows/noleg-stack.git
cd noleg-stack
chmod 777 setup.sh

cat setup.sh | sed -e "s/example.com/your-domain-here.com/g" > setup.sh

./setup.sh
```

If this doesn't work for you or you would like to lean a few things, follow the step by step instructions below.


Assumptions
===========

This post assumes that you:

   - have used nodejs before
   - have setup web servers before
   - have used linux/ubuntu before
   - are able to setup your own DNS settings


Boot
====

Startup your Ubuntu Server. I'm using an M1.Micro on Amazon's EC2 running Ubuntu Server 12.04.3 LTS. 

Make sure you open up port 80 and 22 on the security group or firewall. Also setup your DNS servers to point beta and www to the server's public IP address. 

You can open up port 3000 and 2368 if you want to do some individual node site testing too.

Now SSH into your server. 



Installations
=============

Nginx
----

Install nginx using the command 

```sh
sudo apt-get update
sudo apt-get install -y nginx
sudo nginx 
```
Test it works by going to www.example.com. 

Having trouble? Try the [official nginx docs.](http://wiki.nginx.org/Install)

Git
---

Install git with

```sh
sudo apt-get install -y git
git --version
```

If it works, you should get a version printed at the end.

Having trouble? Try the [official git book.](http://git-scm.com/book/en/Getting-Started-Installing-Git)

MongoDB
-------

Install mongo with

```sh
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/mongodb.list
sudo apt-get update
sudo apt-get install mongodb-10gen
mongo --version
```

You should get mongoDB's version printed at the end if this worked. If not, try the [MongoDB Install Guide](http://docs.mongodb.org/manual/tutorial/install-mongodb-on-ubuntu/).


Nodejs
------

Install nodejs using the following commands. 
```sh
sudo apt-get install -y python-software-properties python g++ make
sudo add-apt-repository -y ppa:chris-lea/node.js
sudo apt-get update
sudo apt-get install -y nodejs
node -v
```

If it worked, the last line should print out the nodejs version.

Having trouble? Try the [official nodejs docs.](https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager)


Some Global NPM Packages
-----------------

We will need a few global nodejs packages later on so lets install them now.
```sh
sudo npm install -g forever express
```


Get Config Files
---------

Included in this repo are some config files. Lets get them now to use later on. 

```sh
cd /tmp
git clone https://github.com/garrows/noleg-stack.git
``` 



Setup A Git Server 
==================

We will setup git to be accessed over ssh. Since you will probably be sharing access, we will create a special user that only has access to git commands and only accessible using approved keypairs instead of a password.

Lets setup the user first and add it to the www-data group which was setup by nginx. 

```sh
sudo adduser --shell $(which git-shell) --gecos 'git version control' --disabled-password git
sudo usermod -a -G www-data git
sudo chsh -s /usr/bin/git-shell git

sudo mkdir -p /home/git/.ssh
sudo touch /home/git/.ssh/authorized_keys
sudo chmod 600 /home/git/.ssh/authorized_keys
sudo chmod 700 /home/git/.ssh
sudo chown -R git:git /home/git/
```

You can setup your accepted public keys now by putting them in the authorized_keys file. If you are on ec2, you can use the generated key if you want.

```sh
cat /home/ubuntu/.ssh/authorized_keys | sudo tee -a /home/git/.ssh/authorized_keys
```

If you want to be able to commit to the git repo while being on the ec2 instance, you can generate a keypair on the server for the ubunut user to be trusted by the git user.
```sh 
ssh-keygen -t rsa -N '' -f /home/ubuntu/.ssh/id_rsa
cat /home/ubuntu/.ssh/id_rsa.pub | sudo tee -a /home/git/.ssh/authorized_keys
```


Now setup an empty git repository.
```sh
sudo mkdir -p /opt/git/website.git
cd /opt/git/website.git
sudo git --bare init

sudo chown -R git:www-data /opt/git/website.git
```

If everything is setup correctly, you should be able to clone the empty repo remotely (ignore the empty repository warning).

```sh
cd /tmp/
git clone git@example.com:/opt/git/website.git
```

If you had troubles or want some more informaiton on setting up a git server, you can try the [git book](http://git-scm.com/book/en/Git-on-the-Server-Setting-Up-the-Server). [This post](https://github.com/alghanmi/ubuntu-desktop_setup/wiki/Git-Local-Repository-Setup-Guide) was also very useful.




Generate Skelleton Node Sites
=============================

The global npm module express is able to generate a skelleton webapp by running the express command. We could just generate the app directly in the /opt/git/website.git directory but we will have to keep fixing permissions so lets generate this in a temp directory and commit it using the proper git workflow. You can of course do this on you computer instead.

```sh
cd /tmp/
git clone git@example.com:/opt/git/website.git
cd website

express --force --sessions --css stylus --ejs www

echo "node_modules" > .gitignore
git add .
git commit -m "Initial commit"
git push origin master
```

You will now have a blank web app commited to your repository. You can do a git pull on your local machine to get a copy. If you would like to give it a test out, you must run npm install first to download the packages. 

There are more options to the express command that are documented on the [official website](http://expressjs.com/guide.html#executable)

Lets also setup a Ghost blog separately so we can demonstrate virtual hosts (running multiple sites on the one server). 

```sh
cd /tmp/website
wget https://ghost.org/zip/ghost-0.4.0.zip
sudo apt-get install unzip
unzip ghost-0.4.0.zip -d blog
rm ghost-0.4.0.zip

git add .
git commit -m "Added blog"
git push origin master
```

You might want to update the Ghost link version from above to the latest.

By default Ghost blog's database is a local sqlite database. Lets move it out of its default directory so we don't destroy its contents when we deploy new code.

```sh
sudo mkdir -p /opt/ghostdb
sudo cp -R /tmp/website/blog/content /opt/ghostdb
sudo chown -R git:www-data /opt/ghostdb
cp config.js config.js.orig
cat config.js.orig | sed -e "s/__dirname/\'\/opt\/ghostdb\'/g" > config.js

git add config.js config.js.orig
git commit -m "Updated ghost config so the database is not lost"
git push orgin master

```

Here are the [gettting started docs](https://github.com/TryGhost/Ghost) in case you ran into troubles.




Auto Publish Node Sites with Git Hooks
======================================

So now we have an express site and a ghost blog but they aren't running anywhere. Git hooks are located in the /opt/git/website.git/hooks/ directory and are basically scripts that will run automatically by git when you commit a change. We can use these to checkout the code to another directory to be run by a daemon. 

First setup the folder permissions with this
```sh
sudo chgrp -R www-data /var/www
sudo chmod -R g+w /var/www
```

Lets create the script /opt/git/website.git/hooks/post-commit from the sample in this repo. 

```sh

cp /tmp/noleg-stack/post-receive.sh /opt/git/website.git/hooks/post-receive
sudo chmod 755 /opt/git/website.git/hooks/post-receive
sudo chown git:www-data /opt/git/website.git/hooks/post-receive

```

Now lets test it by committing something. 

```sh
cd /tmp/website
touch README.md
git add README.md
git commit -m "Added readme to test auto publish"
git push
```

If everything worked you should see a big log of npm installs and a symbolic link at /var/www/current pointing to the latest version of the code. The reason we create a fresh install each commit is if the install or script fails, the link isn't updated and the current code continues to run just fine.

You can test your website now by starting node.
```sh
sudo node /var/www/current/www/app.js
sudo node /var/www/current/blog/index.js
```
Then go to http://example.com:3000 and http://example.com:2368. Don't worry about the ports, we will get them fixed soon. Once you are done, terminate those node processes.

The git hook will also look for the upstart processes node-www and node-blog and restart them if needed. We create them in the next step so it won't do anything right now.




Configure Node to Run As A Service
==================================

We have our two node apps working now but we need a way to keep node running after reboots and unhandled exception. We will use the upstart.conf config file that starts the [forever](https://npmjs.org/package/forever) npm command as a [upstart daemon](http://upstart.ubuntu.com/). Forever will restart node when it crashes or exits unexpectedly and upstart will start the daemon after system reboots. 

```sh

cat /tmp/noleg-stack/upstart.conf | sed -e "s/%APPLICATION%/node-www/g" | sed -e "s/%PATH%/\/var\/www\/current\/www\/app.js/g" > node-www.conf
 
cat /tmp/noleg-stack/upstart.conf | sed -e "s/%APPLICATION%/node-blog/g" | sed -e "s/%PATH%/\/var\/www\/current\/blog\/index.js/g"> node-blog.conf
 
chmod 777 node-www.conf
chmod 777 node-blog.conf
sudo mv node-*.conf /etc/init/

```

To help increase security, its a good idea to run the node process as its own user. Lets make one called 'nodeuser'.

```sh

sudo adduser --gecos 'node daemon user' --disabled-password nodeuser
sudo usermod -a -G www-data nodeuser
sudo usermod -a -G git nodeuser

```

We also need a directory setup for the logs to go

```sh

sudo mkdir -p /var/log/node
sudo chown nodeuser:www-data /var/log/node

```

The git hook we setup earlier will try to restart the upstart jobs every time it updates the code. Ubuntu only allows privileged (root) users restart upstart jobs so we need to add a rule into the sudoers directory to tell ubuntu that the git user can do this. I would prefer not to give full rights here but I don't see any other way. This should be secure though since nobody should be able to modify the hook remotely. 

```sh

echo "git ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/node-restart
sudo chmod 440 /etc/sudoers.d/node-restart

```

Now lets start the services ourselves. 

```sh

sudo start node-www
sudo start node-blog

```

If everything went to plan you should have 2 sites running http://example.com:3000 and http://example.com:2368. If the blog (http://example.com:2368) doesn't work, don't worry, that is because of the host ip address in the config. Nginx will fix this for us.




Configure Nginx Virtual Hosts
=============================

Now that we have two separate node processes running on different ports, we need to tell nginx to route different hostnames and urls to the different ports. Here is the summary of the configs we will setup:

* www.example.com -> port 3000
* example.com -> Redirect to www.example.com
* www.example.com/blog -> port 2368

We will use nginx.conf as a base config file for nginx that we can substitute some values into for our purposes. 

```sh

cat /tmp/noleg-stack/nginx.conf | sed -e "s/%APPLICATION%/example.com/g" | sed -e "s/%PORTWWW%/3000/g" | sed -e "s/%PORTBLOG%/2368/g" > example.com

sudo mv example.com /etc/nginx/sites-available/example.com

sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/example.com

sudo service nginx restart

```

Now, if that worked, you should be all set with your sites running on www.example.com and www.example.com/blog so congratulations. 



Feedback
========

Please if you have found any errors or have any suggestions, either submit an issue, make a pull request or simply email me at glen.arrowsmith@gmail.com. I hope this helped you out in some way.