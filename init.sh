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

#./installSoftware.sh
#./configureServer.sh
#./setupBasicSite.sh $DOMAIN 3000

echo "All done. Try going to http://$DOMAIN/ now."
