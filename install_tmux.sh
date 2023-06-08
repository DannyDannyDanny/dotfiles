#!/bin/bash

echo >&2 "====================================================================="
echo >&2 " >> installing tmux"
TMUX_VERSION=3.3a
curl -LO https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz
tar -zxf tmux-${TMUX_VERSION}.tar.gz
cd tmux-${TMUX_VERSION}/
./configure
make && sudo make install
