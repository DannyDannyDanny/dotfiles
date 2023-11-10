#!/bin/bash
set -e
TMUX_VERSION=3.3a

echo >&2 "====================================================================="
echo >&2 " >> installing tmux"
echo >&2 " >>> install tmux dependencies"
sudo apt install -y libevent-dev
echo >&2 " >>> downloading file"
curl -LO https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz
echo >&2 " >>> decompressing"
tar -zxf tmux-${TMUX_VERSION}.tar.gz
echo >&2 " >>> changing into tmux src"
cd tmux-${TMUX_VERSION}/
echo >&2 " >>> running .configure"
./configure
echo >&2 " >>> listing file in current dir"
echo >&2 $(ls -la)

echo >&2 " >>> running .configure"
make && sudo make install

echo >&2 " >>> link tmux config from dotfiles"
ln -s -f /tmp/dotfiles/.tmux.conf ~/.tmux.conf
