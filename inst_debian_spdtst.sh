#!/bin/bash

apt-get update

apt-get -y install curl
curl -s https://install.speedtest.net/app/cli/install.deb.sh | bash
apt-get -y install speedtest

#chmod -x `basename "$0"`