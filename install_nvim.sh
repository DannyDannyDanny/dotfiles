#!/bin/bash
NVIM_VERSION=0.9.0

# Install neovim
echo >&2 "====================================================================="
echo >&2 " >> installing nvim"
echo >&2 " >>> installing libfuse2"
sudo apt-get install -y libfuse2
echo >&2 " >>> downloading nvim"
# curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
curl -LO https://github.com/neovim/neovim/releases/download/v$(NVIM_VERSION)/nvim.appimage

echo >&2 " >>> changing nvim.appimage mode bits (u+x)"
chmod u+x nvim.appimage

echo >&2 " >>> extracting from ./nvim.appimage"
./nvim.appimage --appimage-extract

echo >&2 " >>> extracted images version"
echo >&2 $(./squashfs-root/AppRun --version)

echo >&2 " >>> moving squashfs-root"
sudo mv squashfs-root /

echo >&2 " >>> exposing nvim globally"
# sudo ln -s /squashfs-root/AppRun /usr/bin/nvim
sudo ln -s /squashfs-root/AppRun /bin/nvim
