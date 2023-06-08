#!/bin/bash

# Install neovim
echo >&2 "====================================================================="
echo >&2 " >> installing nvim"
# curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
NVIM_VERSION=0.9.0
curl -LO https://github.com/neovim/neovim/releases/tag/v${NVIM_VERSION}/download/nvim.appimage
chmod u+x nvim.appimage
./nvim.appimage
