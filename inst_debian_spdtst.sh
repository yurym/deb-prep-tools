#!/bin/bash

# https://www.speedtest.net/apps/cli

apt update
apt -y install curl
curl -s https://install.speedtest.net/app/cli/install.deb.sh | bash
apt -y install speedtest
