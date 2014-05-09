Simple Node & Git Server Setup Scripts
======================================

All you need to do is run the following commands on a fresh server (replace example.com with your domain) and you are all set.

```bash
#!/bin/bash

DOMAIN=example.com

sudo apt-get install -y git
git clone https://github.com/garrows/noleg-stack.git
cd noleg-stack
chmod 777 *.sh

./installSoftware.sh
./configureServer.sh
/setupBasicSite.sh $DOMAIN 3000

```

Now on your local machine you should be able to do the following to setup a basic site

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
