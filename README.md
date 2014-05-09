Simple Node & Git Server Setup Scripts
======================================

Assumptions
-----------

* You have already booted your server
* You have a DNS entry pointing to the server
* Your sever is running Ubuntu (Tested with 14.04 x64 LTS)
* You're using linux or osx (windows user can do this but ssh key wise is more complex)


Server Setup
------------

Ssh into your server and run the following commands (replace example.com with your domain). You can either run this as a script or run the commands by hand.

```bash
#!/bin/bash

DOMAIN=example.com

sudo apt-get install -y git
git clone https://github.com/garrows/noleg-stack.git
cd noleg-stack
chmod 777 *.sh

./installSoftware.sh
./configureServer.sh
./setupBasicSite.sh $DOMAIN 3000

```

Setup SSH Keys
--------------

For extra security, the git account doesn't not have password authentication or terminal access so we need to setup a trust between your computer and the server using your computers public key.

If you haven't already done this in the past generate your keys.
```bash
ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub | sudo tee -a /home/git/.ssh/authorized_keys
```

Now send the key to the server so it knows to trust you.
```bash
cat ~/.ssh/id_rsa.pub | ssh root@example.com "cat >> /home/git/.ssh/authorized_keys"
cat ~/.ssh/id_rsa.pub | ssh root@example.com "cat >> ~/.ssh/authorized_keys"

```

More information keys can be found at https://help.github.com/articles/generating-ssh-keys


Create and Deploy Your Site
---------------------------

On your local machine do the following to setup a basic site

```bash
# Clone the bare git repo from the server
git clone git@example.com:example.com.git
cd example.com

# Generate an express site
express --force --sessions --css stylus --ejs www
echo "node_modules" > .gitignore

# Add to git and publish
git add .
git commit -m "Initial commit"
git push origin master
```

Once this runs, you should be able to go to http://example.com and see the website you just created.

If it didn't work for you, please open a issue on this repo and I'll help you out.
