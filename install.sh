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

cd $HOME

# Make passwordless sudo work
export SUDO_ASKPASS=/bin/true

# No thank you
rm -rf .oh-my-bash
rm -rf .oh-my-zsh
rm .zshrc

# A bit of a hack
# mv .gitconfig .gitconfig.private

# git clone https://github.com/dcreager/dotfiles-base .dotfiles.base
# git clone https://github.com/dcreager/dotfiles-public -b codespaces --recurse-submodules .dotfiles.public
# $HOME/.dotfiles.base/bin/dotfiles.symlink install

echo >&2 "====================================================================="
echo >&2 " >> installing tmux"
sudo apt-get install -y tmux=3.0a-2ubuntu0.4

# I'd like to use fish, please
echo >&2 "====================================================================="
echo >&2 " >> installing fish"
sudo apt-get install -y fish
sudo chsh -s /usr/bin/fish $USER

# Install fzf
echo >&2 "====================================================================="
echo >&2 " >> installing fzf"
FZF_VERSION=0.40.0
curl -L https://github.com/junegunn/fzf/releases/download/${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tar.gz | tar xzC /bin

# Install neovim
echo >&2 "====================================================================="
echo >&2 " >> installing nvim"
# NVIM_VERSION=0.7.2
sudo apt-get install -y neovim=0.7.2-3~bpo20.04.1~ppa1
# sudo apt-get install -y libfuse2
# mkdir /bin/nvim
# curl -L -o /bin/nvim https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim.appimage
# chmod a+x /bin/nvim
