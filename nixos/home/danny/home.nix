{ pkgs, ... }:
{
  # TODO: remove next two lines from here or from flake.nix
  # home.username = "danny";
  # home.homeDirectory = "/Users/danny";

  programs.home-manager.enable = true;

  # Neovim (user-level, works great on macOS)
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    # extraLuaConfig is also available; we’ll keep your Vimscript as-is:
    extraConfig = ''
      set title
      set go=a
      set mouse=a
      set nohlsearch
      set number
      let mapleader=","

      lua << EOF
        local config_file = os.getenv("HOME")..'/.local/share/nvim_color_scheme'
        local f = io.open(config_file, "r")
        if f ~= nil then
            local system_theme = f:read()
            io.close(f)
            if system_theme == 'dark' then
                vim.cmd("set bg=dark")
            elseif system_theme == 'light' then
                vim.cmd("set bg=light")
            else
                print('warning: expected value "light" or "dark"')
                print('  got:', system_theme)
                print('  expected path:', config_file)
            end
        else
            print('warning: nvim color scheme not found')
            print('  expected path:', config_file)
        end
      EOF

      colorscheme catppuccin " catppuccin-latte, catppuccin-frappe, catppuccin-macchiato, catppuccin-mocha

      " netrw (dir listing) settings
      let g:netrw_liststyle = 3
      let g:netrw_banner = 0
      let g:netrw_browse_split = 3
      let g:netrw_winsize = 25  " % of page

      set listchars=tab:→\ ,space:·,nbsp:␣,trail:•,eol:¶,precedes:«,extends:»
      set clipboard+=unnamedplus

      " Replace-all is aliased to S.
      nnoremap S :%s//g<Left><Left>

      " save file with ,w
      map <leader>w :w<cr><Space>

      " spellcheck
      set spell spelllang=en_us
      setlocal spell! spelllang=en_us
    '';

    plugins = with pkgs.vimPlugins; [
      vim-surround
      vim-gitgutter
      vim-nix
      vimtex
      fzf-vim
      nerdtree
      rainbow
      catppuccin-nvim
      goyo-vim
      limelight-vim
    ];
  };

  # tmux (user-level; same config on macOS and NixOS if you reuse this file)
  programs.tmux = {
    enable = true;
    # Keep portable things in extraConfig:
    extraConfig = ''
      # remap prefix from ^B to Alt-f
      unbind C-b
      set -g prefix M-f
      bind M-f send-prefix

      # nvim 'checkhealth' advice
      set -g focus-events on
      set -sa terminal-overrides ',xterm-256color:RGB'
      set -g default-terminal "screen-256color"

      # indices
      set -g base-index 1
      set -g pane-base-index 1

      # sensible defaults
      set -g mouse on
      setw -g mode-keys vi
      set -g history-limit 100000
      set -g escape-time 20

      # pane movement shortcuts
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # window selection
      bind -r C-h select-window -t :-
      bind -r C-l select-window -t :+

      # split with dash and vbar
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
    '';
    plugins = with pkgs.tmuxPlugins; [
      catppuccin
      tmux-fzf
      extrakto
    ];
  };

  # TODO: Put user-installed binaries here if you want HM to own them (optional)
  # home.packages = with pkgs; [
  # ];

  # First HM version for this user config; bump only if you understand the migration notes.
  home.stateVersion = "24.11";
}

