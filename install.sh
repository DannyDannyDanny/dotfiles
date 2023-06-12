#!/bin/sh
# setup script for codespaces inspired by dcreager/dotfiles

if [ -z "$USER" ]; then
    USER=$(id -un)
fi

echo >&2 "====================================================================="
echo >&2 " Setting up codespaces environment"
echo >&2 ""
echo >&2 " USER        $USER"
echo >&2 " HOME        $HOME"
echo >&2 "====================================================================="

# Make passwordless sudo work
export SUDO_ASKPASS=/bin/true

/bin/bash ./install_tmux.sh
/bin/bash ./install_fzf.sh
/bin/bash ./install_nvim.sh
/bin/bash ./install_fish.sh

cd $HOME

# No thank you
rm -rf .oh-my-bash
rm -rf .oh-my-zsh

# A bit of a hack
# mv .gitconfig .gitconfig.private

git clone https://github.com/dannydannydanny/dotfiles .dotfiles
# git clone https://github.com/dcreager/dotfiles-base .dotfiles.base
# git clone https://github.com/dcreager/dotfiles-public -b codespaces --recurse-submodules .dotfiles.public
# $HOME/.dotfiles.base/bin/dotfiles.symlink install
