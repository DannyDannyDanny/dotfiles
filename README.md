# dotfiles

This repo is an extension of [dannydannydanny/methodology](https://github.com/DannyDannyDanny/methodology/)

1. Debian Setup (+ customizations)
  * pure
  * wsl
  * codespaces
  * github actions
2. Core Tool Chain (fish, tmux, nvim, fzf)
3. Customizations (github via ssh, ...)

## Roadmap:

* ~post OS install~ remove [ubuntu.md](ubuntu.md)
* post post OS install: [firefox-scrolling](firefox-scrolling.md)
* repurpose [server-ip-sync](server-ip-sync.md)
* server cluster roadmap: [server](server.md)
  * add server-sync make-rule for ip-upload python cronjob
  * add server-sync make-rule for server ip fetching (and writing...)
* **low-level configs:**
  * config tmux-local vs tmux-remote
    * remote nested sessions
    * change tmux:pane-switching bindings from arrow keys to vim bindings
* **specific machine level debian config:**
  * codespaces
  * github actions
  * local machine
  * server
* music config:
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

* install [wsl](https://docs.microsoft.com/en-us/windows/wsl/install#install-wsl-command) + WSL specifics

```
wsl --install --web-download -d Debian
# <set username>
# <set password
# debian launches automatically

# launch debian next time
wsl -d Debian
```

* wsl commands
  * delete wsl distribution (to restart): `wsl --unregister Debian`
  * terminate: `wsl --terminate`
  * shutdown: `wsl --shutdown`
  * check status: `wsl --list --verbose`
* inside WSL:
  * config alacritty windows side: `vi /mnt/c/Users/xxxx/AppData/Roaming/alacritty/alacritty.yml`
  * `sudo apt install lsb-release -y` to enable `lsb_release -a`
  * `echo 'nameserver 8.8.8.8' | sudo tee -a /etc/resolv.conf` fix DNS issues
  * config wsl: `sudo -e /etc/wsl.conf'
  * fix wsl dns issue via [stackoverflow](https://askubuntu.com/questions/91543/apt-get-update-fails-to-fetch-files-temporary-failure-resolving-error/91595#comment1911934_91595)
    * write wsl.conf:
      * `sudo touch /etc/wsl.conf`
      * `echo "[network]" | sudo tee /etc/wsl.conf > /dev/null`
      * `echo "generateResolvConf = false" | sudo tee -a /etc/wsl.conf > /dev/null`
    * overwrite resolv.conf:
      * add content `echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null`
  * add private folder symlink: `ln -s -f /mnt/c/Users/<winuser>/Private ~/Private`


### Debian

Once debian is running:

```
# upgdate + upgrade packages
sudo apt update && sudo apt upgrade -y

# the following installs aren't necessary in codespace 🤔
sudo apt install -y git curl # dotfiles deps
sudo apt install -y build-essential ncurses-dev  #  tmux dep

# ssh cloning is available after dotfiles installation - clone to /tmp/ for now
git clone https://github.com/DannyDannyDanny/dotfiles.git /tmp/dotfiles && cd /tmp/dotfiles/
bash install.sh
```


### setup github

```
ssh-keygen -q -t ed25519 -N '' -f ~/.ssh/id_ed25519_github <<<y >/dev/null 2>&1

echo 'older machines might not support ed25519, then use RSA with 4096 bit key'
echo  'ssh-keygen -q -t rsa -b 4096 -N '' -f ~/.ssh/id_rsa_github <<<y >/dev/null 2>&1'

echo 'add ssh to key to github'
echo 'cat ~/.ssh/id_*_github.pub'
echo 'go to https://github.com/settings/ssh/new and add key as <year>-<machine-name>'

# pause because user needs to add key before we continue
read -rsp $'Press any key to continue...\n' -n1 key

echo 'adding key to ssh-agent'
eval `ssh-agent -s`  # not  just ssh-agent -s
ssh-add ~/.ssh/id_*_github
echo 'private repos can now be cloned via ssh'
echo 'repos can now be pushed to via ssh'
```

#### dotfiles repo via ssh

```
echo 'clone and git config dotfiles repo'
git clone git@github.com:DannyDannyDanny/dotfiles.git

cd dotfiles
git config user.name "DannyDannyDanny"
git config user.email "dth@taiga.ai"
git config pull.rebase false
cd ..

```
* remove section from ubuntu.md
* change install script(s) to download file to `/tmp/` instead of working directory
* consider adding [more error handling](https://tecadmin.net/bash-error-detection-and-handling-tips-and-tricks/) to install scripts

### add sshd persistency

* for bash use github docs: [auto-launching-ssh-agent-on-git-for-windows](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/working-with-ssh-key-passphrases#auto-launching-ssh-agent-on-git-for-windows)
* fish version ([src](https://gist.github.com/josh-padnick/c90183be3d0e1feb89afd7573505cab3?permalink_comment_id=3570155#gistcomment-3570155))
* also run: `ssh-add ~/.ssh/id_*_github`

***

* sort thse notes
  * configure git (inspired by `make setup_git`)
    * TODO: remove email from makefile
    * install [build-essential](https://askubuntu.com/a/753113/882709) to get `make`
  * install autohotkey
    * add script: shift and space + caps and escape: `sas-cae.ahk`
