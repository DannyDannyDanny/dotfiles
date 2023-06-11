#!/bin/bash

# I'd like to use fish, please
echo >&2 "====================================================================="
echo >&2 " >> installing fish"
sudo apt-get install -y fish

echo >&2 " >>> changing shell to fish"
sudo chsh -s /usr/bin/fish $USER

echo >&2 " >>> echo $0"
