# HOME SERVERS

## Roadmap

* [.] auto-setup ssh + ngrok on all machines
  * [X] client machines automation
    * [X] read ssh commands in [ubuntu](ubuntu.md)
    * [X] generate ssh key pair
    * [X] ~~write public key to gist~~
    * [X] add ssh public keys to version control `dotfiles/.ssh/authorized_keys`
  * [.] server machine
    * [X] fetch keys and add to `.ssh/authorized_keys`
    * [X] install [ngrok](https://ngrok.com/download)
    * [X] setup [ngrok](https://dashboard.ngrok.com/get-started/setup)
    * [ ] add make rule to [create ssh-credential](https://ngrok.com/docs/api#api-ssh-credentials)
      * [ ] test ssh public key is added to [ngrok API](no-install grok.md)
    * [ ] add make-rules to setup ssh
    * [ ] setup [ngrok as service](https://stackoverflow.com/a/50808709)
  * [ ] test setup
    * [ ] install and setup `ngrok` on test machine
    * [ ] add authorized keys to version control (?)
    * [ ] repurpose [server-ip-sync](server-ip-sync.md)
  * [ ] research replacing `ngrok` with [sish](https://github.com/antoniomika/sish)
* [X] set up lenovo machine as thin client
  * [ ] run pop os??
* [ ] keepass get comfy
  * [ ] set up keepass on all devices
  * [ ] set up ssh keys in keepass
* [.] set up home server cluster
  * [ ] setup jetson OS (nvidia distro)
    * [ ] Jetson Nano Developer Kit SD Card Image [link](https://developer.nvidia.com/embedded/learn/get-started-jetson-nano-devkit)
      * [ ] Mac + Lenovo access
  * [.] setup raspberry pi
    * [X] install Raspberry Pi OS Lite (32-bit) [link](https://www.raspberrypi.com/software/operating-systems/#raspberry-pi-os-32-bit)
      * [ ] Mac + Lenovo access
    * [ ] setup [sftp](https://linuxconfig.org/how-to-setup-sftp-server-on-ubuntu-22-04-jammy-jellyfish-linux)
  * [.] reinstall OS on imac
    * [.] obtain CD
    * [ ] decide imac purpose
    * [ ] decide what OS to run
* [ ] move music collection from e540 to HDD
* [ ] jailbreak iPads


## Servers

| machine      | name  |
|--------------|-------|
| MacBook Pro  | name1 |
| MacBook Air  | name2 |
| Lenovo E540  | name3 |
| Lenovo E560  | ...   |
| Lenovo X200s | ...   |
| Raspberry Pi | ...   |
| Jetson Nano  | ...   |
