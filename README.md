# dotfiles

This repo is an extension of [dannydannydanny/methodology](https://github.com/DannyDannyDanny/methodology/)

## Roadmap:

* post OS install: [ubuntu](ubuntu.md)
* post post OS install: [firefox-scrolling](firefox-scrolling.md)
* repurpose [server-ip-sync](server-ip-sync.md)
* server cluster roadmap: [server](server.md)
  * add server-sync make-rule for ip-upload python cronjob
  * add server-sync make-rule for server ip fetching (and writing...)
* **low-level configs:**
  * config tmux-local vs tmux-remote
    * remote nested sessions
    * change tmux:pane-switching bindings from arrow keys to vim bindings
* **specific machine level config:**
  * ~config mac local machine~
  * debian local machine
  * debian server
* music config:
  * mpd, mpc, ncmpcpp
    * [Mac guide](https://killtheyak.com/install-mpd-mpc-ncmpcpp/)
    * [config guide for mac](https://computingforgeeks.com/install-configure-mpd-ncmpcpp-macos/)
  * test on new machine with music dir
  * [fonts](https://www.programmingfonts.org/)

***

## Windows

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
* install [wsl](https://docs.microsoft.com/en-us/windows/wsl/install#install-wsl-command) + WSL specifics
  * fix wsl dns issue via [stackoverflow](https://askubuntu.com/questions/91543/apt-get-update-fails-to-fetch-files-temporary-failure-resolving-error/91595#comment1911934_91595)
    * write wsl.conf:
      * `sudo touch /etc/wsl.conf`
      * `echo "[network]" | sudo tee /etc/wsl.conf > /dev/null`
      * `echo "generateResolvConf = false" | sudo tee -a /etc/wsl.conf > /dev/null`
    * overwrite resolv.conf:
      * add content `echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null`
  * add alacritty config: `/mnt/c/Users/<winuser>/AppData/Roaming/alacritty/alacritty.yml`
  * add private folder symlink: `ln -s -f /mnt/c/Users/<winuser>/Private ~/Private`
  * setup [ssh github](ubuntu.md#setup-ssh-key-for-github)
  * configure git (inspired by `make setup_git`)
    * TODO: remove email from makefile
    * install [build-essential](https://askubuntu.com/a/753113/882709) to get `make`
  * install autohotkey
    * add script: shift and space + caps and escape: `sas-cae.ahk`
