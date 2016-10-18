#!/bin/bash

if [[ $DOMAIN -lt 2 ]]
then
    echo "Make sure you have the $DOMAIN variable set. Aborting."
    exit
fi

set -e
set -v

sudo apt-get install -y git
git clone https://github.com/garrows/noleg-stack.git

cd noleg-stack
chmod 777 *.sh

./installSoftware.sh
./configureServer.sh
./setupBasicSite.sh $DOMAIN 3000

echo "All done. Try the following:"
echo "cd your-node-project"
echo "git remote add production git@$DOMAIN:$DOMAIN.git"
echo "git push production"
echo "open https://$DOMAIN"
