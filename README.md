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

* disable system sounds: `start menu search: "change system sounds" -> set profile to None`
* change language / keyboard layout to `en_US`
* get local admin rights
* [install powertoys](https://docs.microsoft.com/en-us/windows/powertoys/install#install-with-windows-executable-file-via-github)
  * remap CAPS LOCK to L-CTRL
* install glasswire network monitor
* install basic miktex (for LaTeX)
* install [alacritty](https://alacritty.org/) (use the installer, not portable)
* install [wsl](https://docs.microsoft.com/en-us/windows/wsl/install#install-wsl-command) + WSL specifics
  * fix wsl dns issue via [stackoverflow](https://askubuntu.com/questions/91543/apt-get-update-fails-to-fetch-files-temporary-failure-resolving-error/91595#comment1911934_91595)
    * write wsl.conf:
      * `sudo touch /etc/wsl.conf`
      * `echo "[network]" | sudo tee /etc/wsl.conf > /dev/null`
      * `echo "generateResolvConf = false" | sudo tee -a /etc/wsl.conf > /dev/null`
    * overwrite resolv.conf:
      * kill symlink `rm /etc/resolv.conf`
      * write file `touch /etc/resolv.conf`
      * add content `echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null`
  * add alacritty config: `/mnt/c/Users/<winuser>/AppData/Roaming/alacritty/alacritty.yml`
  * add private folder symlink: `ln -s -f /mnt/c/Users/<winuser>/Private ~/Private`
* follow Ubuntu guide:
  * `apt install neovim` (NVIM v0.4.3) - consider
  * `apt install texlive texlive-latex-extra`
  * setup [ssh github](ubuntu.md#setup-ssh-key-for-github)
  * install [zsh + omz](ubuntu.md#apt-package)
  * clone this (dotfiles) repo and `cd dotfiles`
    * configure git (inspired by `make setup_git`)
      * TODO: remove email from this file
    * install [build-essential](https://askubuntu.com/a/753113/882709) to get `make`
      * run `make setup_locale setup_zshrc setup_tmux_a setup_nvim setup_editorconfig setup_client_mynetwork`
  * TODO: move up: install [brew](ubuntu#brew) (should be done before install zsh / omz)
* Next steps:
  * TODO: configure nvim clipboard to use system clipboard
  * TODO: nvim + tmux pasteboard should play with windows pasteboard
