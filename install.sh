#!/bin/sh
# setup script for codespaces inspired by dcreager/dotfiles
set -e

if [ -z "$USER" ]; then
    USER=$(id -un)
fi

echo >&2 "====================================================================="
echo >&2 " Setting up codespaces environment"
echo >&2 " USER        $USER"
echo >&2 " HOME        $HOME"

# Make passwordless sudo work
export SUDO_ASKPASS=/bin/true

/bin/bash ./install_tmux.sh
/bin/bash ./install_fzf.sh
/bin/bash ./install_nvim.sh
/bin/bash ./install_fish.sh
