#!/bin/bash

# fish version on ubuntu 22.04
# FISH_VERSION=3.3.1+ds-3
# fish version on ubuntu 20.04 (codespaces ubuntu version)
FISH_VERSION=3.1.0-1.2

# I'd like to use fish, please
echo >&2 "====================================================================="
echo >&2 " >> installing fish"
sudo apt-get install -y fish=${FISH_VERSION}

echo >&2 " >>> changing shell to fish"
sudo chsh -s /usr/bin/fish $USER

echo >&2 " >>> echo $0"
