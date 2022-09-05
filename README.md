# dotfiles

This repo is an extension of [dannydannydanny/methodology](https://github.com/DannyDannyDanny/methodology/)

## Roadmap:

* post OS install: [ubuntu](ubuntu.md)
* post post OS install: [firefox-scrolling](firefox-scrolling.md)
* repurpose [server-ip-sync](server-ip-sync.md)
* server cluster roadmap: [server](server.md)
* extend *makefile*:
  * **low-level configs:**
    * config zsh
    * config nvim
    * config tmux-local
    * config tmux-remote
  * **machine level config:**
    * config mac local machine
    * config ubuntu local machine
    * config ubuntu server
* [o] configure **tmux**:
  * [X] remote nested sessions
  * [X] change tmux:pane-switching bindings from arrow keys to vim bindings
* [ ] add server-sync make-rule for ip-upload python cronjob
* [ ] add server-sync make-rule for server ip fetching (and writing...)
* [ ] nvim / lvim
  * [ ] make-rule for setting up `$HOME/.venvs/nvim/bin/python`
  * [ ] make-rules for getting nvim checkhealth up to speed
* [ ] music config:
  * mpd, mpc, ncmpcpp
    * [Mac guide](https://killtheyak.com/install-mpd-mpc-ncmpcpp/)
    * [config guide for mac](https://computingforgeeks.com/install-configure-mpd-ncmpcpp-macos/)
  * test on new machine with music dir
  * [fonts](https://www.programmingfonts.org/)

***

## Windows

I'm back on a windows machine and still learning how to make it nice.

Here's what I've done so far:

* change language / keyboard layout to `en_US`
* get local admin rights
* [install powertoys](https://docs.microsoft.com/en-us/windows/powertoys/install#install-with-windows-executable-file-via-github)
  * remap CAPS LOCK to L-CTRL
* install [alacritty](https://alacritty.org/) (use the installer, not portable)
* install [wsl](https://docs.microsoft.com/en-us/windows/wsl/install#install-wsl-command)
  * temporarily fix ubuntu dns issue via [stackoverflow](https://askubuntu.com/a/91596/882709)
    * add config: `/mnt/c/Users/XXX/AppData/Roaming/alacritty/alacritty.yml` (here `XXX` is the windows users, and not linux user)
  * setup [ssh github](ubuntu.md#setup-ssh-key-for-github)
  * setup [zsh](ubuntu.md#apt-package) + omz
  * clone this (dotfiles) repo and `cd dotfiles`
    * configure git (inspired by `make setup_git`)
      * TODO: remove email from this file
    * run `make setup_locale setup_zshrc setup_tmux_a setup_nvim setup_editorconfig setup_client_mynetwork`
