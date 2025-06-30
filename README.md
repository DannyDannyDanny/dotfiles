# dotfiles

This repo is an extension of [dannydannydanny/methodology](https://github.com/DannyDannyDanny/methodology/)

1. Debian Setup (+ customizations)
  * pure see [issue 3]([url](https://github.com/DannyDannyDanny/dotfiles/issues/3))
  * [wsl](#wsl)
  * codespaces
  * github actions
2. Core Tool Chain (fish, tmux, nvim, fzf)
3. Customizations (github via ssh, ...)

## Roadmap:

* ~post OS install~ remove [ubuntu.md](ubuntu.md)
* configure [firefox-scrolling](firefox-scrolling.md) via terminal
* repurpose [server-ip-sync](server-ip-sync.md)
* server cluster roadmap: [server](server.md)
  * add server-sync make-rule for ip-upload python cronjob
  * add server-sync make-rule for server ip fetching (and writing...)
* **refine install scripts**
  * :memo: add logging (to `/tmp/??`)
  * :goal_net: add [error handling](https://tecadmin.net/bash-error-detection-and-handling-tips-and-tricks/)
    (if one crashes, stop or continue print summary at the end)
  * :art: check for `nvim checkhealth` status
  * make tmux nice: https://www.youtube.com/watch?v=DzNmUNvnB04
* **low-level configs:**
  * config tmux-local vs tmux-remote
    * remote nested sessions
    * change tmux:pane-switching bindings from arrow keys to vim bindings
* **specific machine level debian config:**
  * codespaces
  * github actions
  * local machine
    * [debian swap space](https://www.digitalocean.com/community/tutorials/how-to-add-swap-space-on-debian-11)
  * server
* **music config**
  * mpd, mpc, ncmpcpp
  * test on new machine with music dir
  * [fonts](https://www.programmingfonts.org/)
    * how does this relate to nerdfonts?

## Debian Setup

### Windows

* disable system sounds: `start menu search: "change system sounds" -> set profile to None`
* change language / keyboard layout to `en_US`
* get local admin rights
* [install powertoys](https://docs.microsoft.com/en-us/windows/powertoys/install#install-with-windows-executable-file-via-github)
  * remap CAPS LOCK to L-CTRL
* tmux pasteboard should play with windows pasteboard
  * configure nvim clipboard to use system clipboard - had to setup some windows yank script
* install portmaster network monitor
  * https://safing.io/blog/2022/10/27/portmaster-reaches-1.0/
* install basic miktex (for LaTeX)
  * `apt install texlive texlive-latex-extra` (?)
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

# install dotfiles
bash install.sh

# hop back out
cd ..
```

### Clone repo HTTP method
```
git clone https://github.com/DannyDannyDanny/dotfiles.git
```

### add sshd persistency

* for bash use github docs: [auto-launching-ssh-agent-on-git-for-windows](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/working-with-ssh-key-passphrases#auto-launching-ssh-agent-on-git-for-windows)
* fish version ([src](https://gist.github.com/josh-padnick/c90183be3d0e1feb89afd7573505cab3?permalink_comment_id=3570155#gistcomment-3570155))
* also run: `ssh-add ~/.ssh/id_*_github`


### fisher
```
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
fisher install jorgebucaran/nvm.fish
```

***

* sort thse notes
  * configure git (inspired by `make setup_git`)
    * TODO: remove email from makefile
    * install [build-essential](https://askubuntu.com/a/753113/882709) to get `make`
  * install autohotkey
    * add script: shift and space + caps and escape: `sas-cae.ahk`
  * [neofetch](https://github.com/dylanaraps/neofetch/)
* linux main drive config:
  * **desktop environment** journal:
     I have been comfortly (but numbly) been running GNOME 43.9 for the past couple years.
     Xfce 4.18 is a bit janky and requires significant customization (e.g. keyboard bindings, trackpad gestures)
     to be usable. It is super lightweight and customizable and I can see myself going back
     when it matures - or when limited by hardware.
     Going to try KDE Plasma. I've been recommended it several times and KDE is also behind
     Krita (painting program) and kdenlive (video editing program).
