# dotfiles

[`nixos`](https://nixos.org/) + [`tmux`](https://github.com/tmux/tmux/?tab=readme-ov-file#welcome-to-tmux) + [`fish`](https://fishshell.com/) + [`neovim`](https://neovim.io/)

This repo is an extension of [dannydannydanny/methodology](https://github.com/DannyDannyDanny/methodology/)

## Roadmap:

* configure [firefox-scrolling](firefox-scrolling.md) via terminal
* server cluster roadmap: [server](server.md)
* :art: check for `nvim checkhealth` status
* make tmux nice: https://www.youtube.com/watch?v=DzNmUNvnB04
* [fonts](https://www.programmingfonts.org/) - how does this relate to nerdfonts?
* [HN: What's on your home server](https://news.ycombinator.com/item?id=34271167)
* Jetson Nano Developer Kit SD Card Image [link](https://developer.nvidia.com/embedded/learn/get-started-jetson-nano-devkit)
* Raspberry Pi OS Lite (32-bit) [link](https://www.raspberrypi.com/software/operating-systems/#raspberry-pi-os-32-bit)


## Windows

* disable system sounds: `start menu search: "change system sounds" -> set profile to None`
* change language / keyboard layout to `en_US`
* [install powertoys](https://docs.microsoft.com/en-us/windows/powertoys/install#install-with-windows-executable-file-via-github)
  * remap CAPS LOCK to L-CTRL
* install [alacritty](https://alacritty.org/) (use the installer, not portable)
  * add alacritty config: `/mnt/c/Users/<winuser>/AppData/Roaming/alacritty/alacritty.yml`

### WSL

Install via [nix-community/NixOS-WSL Quickstart](https://github.com/nix-community/NixOS-WSL?tab=readme-ov-file#quick-start) :white_check_mark:
Setup dotfiles / config via github:
```bash
# git and github CLI tool in a temp shell
nix-shell -p gh git
# authenticate
gh auth login
# clone dotfiles
gh repo clone dannydannydanny/dotfiles
# checkout the appropriate branch
git checkout feat/wsl-neovim-update
# rebuild system with
sudo nixos-rebuild switch --flake ~/dotfiles/nixos/
```

### Clone repo SSH method
Skip this if you don't plan on getting SSH access to github repos and clone with HTTP instead
#### generate ssh
```
ssh-keygen -q -t ed25519 -N '' -f ~/.ssh/id_ed25519_github <<<y >/dev/null 2>&1

# echo 'older machines might not support ed25519, then use RSA with 4096 bit key'
# echo  'ssh-keygen -q -t rsa -b 4096 -N '' -f ~/.ssh/id_rsa_github <<<y >/dev/null 2>&1'

# add the output to https://github.com/settings/ssh/new
cat ~/.ssh/id_*_github.pub
# add to https://github.com/settings/ssh/new
```

#### activate ssh
```
echo 'adding key to ssh-agent'
eval `ssh-agent -s`  # if using fish shell run: eval "$(ssh-agent -c)"
ssh-add ~/.ssh/id_*_github

# download dotfiles repo
git clone git@github.com:DannyDannyDanny/dotfiles.git

# config git
cd dotfiles
git config user.name "DannyDannyDanny"
git config user.email "dth@taiga.ai"
git config pull.rebase false
git config push.autoSetupRemote true
# more git config: https://blog.gitbutler.com/how-git-core-devs-configure-git/

# install dotfiles
bash install.sh

# hop back out
cd ..
```

