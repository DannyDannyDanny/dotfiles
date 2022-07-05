## Document Roadmap

* ubunutu script should install all programs in one go (and not ask go Y every time)
* add necessary packages:
sudo add-apt-repository ppa:aslatter/ppa # for alacritty
* oh-my-zsh install
* ssh setup from vimwiki
* git clone dotfiles
* cd dotfiles and run makefile
  * (make toplevel rules, i.e `setup_nerdfonts` is a sub of `setup_alacritty`)

```
## apt package - startup installation for ubuntu clients
sudo apt install git -y           # version control
# sudo apt install neovim -y      # brew install nvim to get version 0.7
sudo apt install librewolf -y     # add librewolf repo first
sudo apt install qutebrowser -y   # minimal vim-binding browser
sudo apt install gnome-tweaks -y  # tool to remap caps to ctrl
sudo apt install alacritty -y     # add alacritty repo first
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

## Snap packages
```
snap install codium --classic
```

## Homebrew packages

Install [brew](https://brew.sh/) and brew install:

```
brew install yt-dlp
brew install neovim
```


## Mail & Calendar

Use thunderbird to attach to just about any mail + cal clients


## Password Manager

* [X] Start using keepass
* [ ] Research version controlling DB
* [ ] Start using a secret file to unlock DB


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
