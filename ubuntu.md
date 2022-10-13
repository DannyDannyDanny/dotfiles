## Document Roadmap

* oh-my-zsh install
* ssh setup from vimwiki
* git clone dotfiles
* cd dotfiles and run makefile
  * (make toplevel rules, i.e `setup_nerdfonts` is a sub of `setup_alacritty`)
  * replace alacritty with stterm

## Intro

This post-install script is intended to be run directly after ~Uubuntu 22.05~~ Pop_OS installion.
The scipt assumes device is encrypted and user account is protected.
With a strong passphrasses for both.

Generate an ssh key for github

## ssh setup

> :construction: under construction
>
>
> no-prompt ssh keys
> https://stackoverflow.com/a/43235320


### Setup ssh key for github

> :construction: This needs to be turned into a little script or something

The first ssh key is generated for github:

```
ssh-keygen -q -t ed25519 -N '' -f ~/.ssh/id_ed25519_github <<<y >/dev/null 2>&1

# older machines might not support ed25519, then use RSA with 4096 bit key
# ssh-keygen -q -t rsa -b 4096 -N '' -f ~/.ssh/id_rsa_github <<<y >/dev/null 2>&1
```

Log in to github.
Go to [github.com/settings/ssh/new](https://github.com/settings/ssh/new).
Enter a title format in the format `2022-homeserver`.
Enter the key returned by `cat ~/.ssh/id_*_github.pub`.
Now you can clone your private repos and make changes to your public repos.


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

## stterm
* install requirements
  * `sudo apt install libfontconfig1-dev`
  * `sudo apt install libx11-dev`
  * X11/Xft?
* clone from source `git clone https://git.suckless.org/st`
  * > Note: clone it somewhere reasonable (`$HOME/repos`)
* run `sudo make clean install` inside `st/`
* delete `st/config.h`
* link `dotfiles/st/config.h --> $HOME/repos/st/config.h`
  * remember to version control the config.h file


## apt package

startup installation for ubuntu clients.
open terminal, run one code snippet at the time and check that no errors occur:

```
# add external repos
# sudo add-apt-repository ppa:aslatter/ppa    # for alacritty
# replace alacritty with stterm

sudo apt install git -y           # version control
# sudo apt install neovim -y      # brew install nvim to get version 0.7
# install neovim - [src](https://vi.stackexchange.com/a/38348)


# sudo apt install librewolf -y   # add librewolf repo first
sudo apt install qutebrowser -y   # minimal vim-binding browser
sudo apt install gnome-tweaks -y  # tool to remap caps to ctrl
# sudo apt install alacritty -y     # add alacritty repo first
# replace alacritty with stterm
sudo apt install tmux -y          # terminal multiplexer
sudo apt install make -y          # utility to maintain shell program groups
sudo apt install curl -y          # file transfer helper
sudo apt install ffmpeg -y        # audio/video converter
sudo apt install keepass2 -y      # password manager
sudo apt install zsh -y           # install oh-my-zsh to set zsh as default shell

# music setup
sudo apt install mpd -y           # music player daemon
sudo apt install ncmpcpp -y       # ncurses music player controller plus plus
```

Now **[install oh-my-zsh](https://ohmyz.sh/#install) and `reboot`**.



## Snap packages
```
snap install codium --classic
```

## brew

Install [brew](https://brew.sh/) and brew install:

```
brew install yt-dlp
brew install neovim
brew install lf
```


## Mail & Calendar

Use thunderbird to attach to just about any mail + cal clients


## Password Manager

use keepass :key: with secret file

## emojis
use emote: `sudo snap install emote`

## LunarVim

List all plugins

```lua
  { "folke/tokyonight.nvim" },
  {
    "folke/trouble.nvim",
    cmd = "TroubleToggle",
  },

  -- Minimap
  {
    'wfxr/minimap.vim',
    run = "cargo install --locked code-minimap",
    -- cmd = {"Minimap", "MinimapClose", "MinimapToggle", "MinimapRefresh", "MinimapUpdateHighlight"},
    config = function()
      vim.cmd("let g:minimap_width = 10")
      vim.cmd("let g:minimap_auto_start = 1")
      vim.cmd("let g:minimap_auto_start_win_enter = 1")
    end,
  },

  -- Git helper
  {
    "tpope/vim-fugitive",
    cmd = {
      "G",
      "Git",
      "Gdiffsplit",
      "Gread",
      "Gwrite",
      "Ggrep",
      "GMove",
      "GDelete",
      "GBrowse",
      "GRemove",
      "GRename",
      "Glgrep",
      "Gedit"
    },
    ft = { "fugitive" }
  },

  -- extend surround
  {
    "tpope/vim-surround",
    keys = { "c", "d", "y" }
    -- make sure to change the value of `timeoutlen` if it's not triggering correctly, see https://github.com/tpope/vim-surround/issues/117
    -- setup = function()
    --  vim.o.timeoutlen = 500
    -- end
  },

  -- autosave
  {
    "Pocco81/AutoSave.nvim",
    config = function()
      require("autosave").setup()
    end,
  },

  -- show indentation verticals
  {
    "lukas-reineke/indent-blankline.nvim",
    event = "BufRead",
    setup = function()
      vim.g.indentLine_enabled = 1
      vim.g.indent_blankline_char = "▏"
      vim.g.indent_blankline_filetype_exclude = { "help", "terminal", "dashboard" }
      vim.g.indent_blankline_buftype_exclude = { "terminal" }
      vim.g.indent_blankline_show_trailing_blankline_indent = false
      vim.g.indent_blankline_show_first_indent_level = false
    end
  },

  -- lastplace: pick up where you left off
  {
    "ethanholz/nvim-lastplace",
    event = "BufRead",
    config = function()
      require("nvim-lastplace").setup({
        lastplace_ignore_buftype = { "quickfix", "nofile", "help" },
        lastplace_ignore_filetype = {
          "gitcommit", "gitrebase", "svn", "hgcommit",
        },
        lastplace_open_folds = true,
      })
    end,
  },

  -- highlight words under cursor
  {
    "itchyny/vim-cursorword",
    event = { "BufEnter", "BufNewFile" },
    config = function()
      vim.api.nvim_command("augroup user_plugin_cursorword")
      vim.api.nvim_command("autocmd!")
      vim.api.nvim_command("autocmd FileType NvimTree,lspsagafinder,dashboard,vista let b:cursorword = 0")
      vim.api.nvim_command("autocmd WinEnter * if &diff || &pvw | let b:cursorword = 0 | endif")
      vim.api.nvim_command("autocmd InsertEnter * let b:cursorword = 0")
      vim.api.nvim_command("autocmd InsertLeave * let b:cursorword = 1")
      vim.api.nvim_command("augroup END")
    end
  },

  -- smooth scrolling
  {
    "karb94/neoscroll.nvim",
    event = "WinScrolled",
    config = function()
      require('neoscroll').setup({
        -- All these keys will be mapped to their corresponding default scrolling animation
        mappings = { '<C-u>', '<C-d>', '<C-b>', '<C-f>',
          '<C-y>', '<C-e>', 'zt', 'zz', 'zb' },
        hide_cursor = true, -- Hide cursor while scrolling
        stop_eof = true, -- Stop at <EOF> when scrolling downwards
        use_local_scrolloff = false, -- Use the local scope of scrolloff instead of the global scope
        respect_scrolloff = false, -- Stop scrolling when the cursor reaches the scrolloff margin of the file
        cursor_scrolls_alone = true, -- The cursor will keep on scrolling even if the window cannot scroll further
        easing_function = nil, -- Default easing function
        pre_hook = nil, -- Function to run before the scrolling animation starts
        post_hook = nil, -- Function to run after the scrolling animation ends
      })
    end
  },
```
