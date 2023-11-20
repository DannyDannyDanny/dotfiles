### Setup ssh key for connecting to other servers

This next ssh key is generated for internal servers:

```
ssh-keygen -q -t ed25519 -N '' -f ~/.ssh/id_ed25519_mynetwork <<<y >/dev/null 2>&1

# older machines might not support ed25519, then use RSA with 4096 bit key
# ssh-keygen -q -t rsa -b 4096 -N '' -f ~/.ssh/id_rsa_mynetwork <<<y >/dev/null 2>&1
```

The public ssh key is in `~/.ssh/id_*_mynetwork.pub`.
Copy the public key to machines which you want to access with this machine.
Inversely, if you want other machines to ssh to this machine,
copy their public keys to this machine.

#### ssh resources
* [Digital Ocean ssh essentials](https://www.digitalocean.com/community/tutorials/ssh-essentials-working-with-ssh-servers-clients-and-keys)

#### server-side setup checklist
* setup locales (LC_LANGUAGE, LC_ALL)
* install openssh-server
* enable ssh service on startup
* copy workstation public key to server
* ssh via key (i.e no password)
* disable password authentication

## apt package

startup installation for ubuntu clients.
open terminal, run one code snippet at the time and check that no errors occur:

```
#sudo apt-get install software-properties-common
sudo apt-get update
sudo apt-get install neovim -y

# sudo apt install librewolf -y   # add librewolf repo first
sudo apt install qutebrowser -y   # minimal vim-binding browser
sudo apt install gnome-tweaks -y  # tool to remap caps to ctrl
# sudo apt install alacritty -y     # add alacritty repo first
# replace alacritty with stterm
sudo apt install jq -y            # lightweight and flexible command-line JSON processor
sudo apt install make -y          # utility to maintain shell program groups
sudo apt install curl -y          # file transfer helper (also see wget)
sudo apt install ffmpeg -y        # audio/video converter
sudo apt install keepass2 -y      # password manager
sudo apt install zsh -y           # install oh-my-zsh to set zsh as default shell

# music setup
sudo apt install mpd -y           # music player daemon
sudo apt install ncmpcpp -y       # ncurses music player controller plus plus
```

## brew
Install [brew](https://brew.sh/) and `brew install yt-dlp`

## Mail & Calendar
Use thunderbird to attach to just about any mail + cal clients

To get reasonably formatted dates in thunderbird set the locale environment variable `LC_TIME`:
`sudo update-locale LC_TIME=en_DK.UTF-8`

## Password Manager
use keepass :key: (with secret file)
