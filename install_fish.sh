#!/bin/bash
set -e

echo >&2 "====================================================================="
echo >&2 " >> installing fish"

# TODO: autodetect debian11/12
# echo 'deb http://download.opensuse.org/repositories/shells:/fish:/release:/3/Debian_12/ /' | \
echo 'deb http://download.opensuse.org/repositories/shells:/fish:/release:/3/Debian_11/ /' | \
  sudo tee /etc/apt/sources.list.d/shells:fish:release:3.list

# TODO: autodetect debian11/12
# curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:3/Debian_12/Release.key | \
curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:3/Debian_11/Release.key | \
  gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/shells_fish_release_3.gpg > /dev/null

sudo apt update
sudo apt install -y fish

echo >&2 " >>> changing shell to fish"
sudo chsh -s /usr/bin/fish $USER

echo >&2 " >>> link config.fish from dotfiles"
mkdir -p ~/.config/fish
ln -s -f ~/dotfiles/.config/fish/config.fish ~/.config/fish/config.fish

echo >&2 " >>> echo $0"
