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

  # Git configuration
  programs.git = {
    enable = true;
    extraConfig = {
      core = {
        editor = "nvim";
      };
    };
  };

  # Alacritty terminal configuration with conditional theme switching
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding = { x = 8; y = 8; };
        dynamic_padding = true;
        decorations = "buttonless";
        opacity = 0.95;
        startup_mode = "Fullscreen";
        option_as_alt = "Both";
      };
      scrolling = { history = 10000; multiplier = 3; };
      font = {
        size = 13.0;
      };
      cursor = { style = "Block"; unfocused_hollow = true; };
      terminal = {
        shell = {
          program = "${pkgs.fish}/bin/fish";
        };
      };
      # Conditional colors based on system theme
      colors = let
        # Set this to true for light theme, false for dark theme
        # You can change this and run 'darwin-rebuild switch' to switch themes
        isLightTheme = true;
        
        # Catppuccin Latte (Light) colors
        lightColors = {
          primary = { background = "0xeff1f5"; foreground = "0x4c4f69"; };
          cursor = { text = "0xeff1f5"; cursor = "0xdc8a78"; };
          normal = {
            black = "0x5c5f77"; red = "0xd20f39"; green = "0x40a02b"; yellow = "0xdf8e1d";
            blue = "0x1e40af"; magenta = "0xea76cb"; cyan = "0x179299"; white = "0xacb0be";
          };
          bright = {
            black = "0x6c6f85"; red = "0xd20f39"; green = "0x40a02b"; yellow = "0xdf8e1d";
            blue = "0x1e40af"; magenta = "0xea76cb"; cyan = "0x179299"; white = "0xbcc0cc";
          };
        };
        
        # Catppuccin Mocha (Dark) colors
        darkColors = {
          primary = { background = "0x1e1e2e"; foreground = "0xcdd6f4"; };
          cursor = { text = "0x1e1e2e"; cursor = "0xf5e0dc"; };
          normal = {
            black = "0x45475a"; red = "0xf38ba8"; green = "0xa6e3a1"; yellow = "0xf9e2af";
            blue = "0x89b4fa"; magenta = "0xf5c2e7"; cyan = "0x94e2d5"; white = "0xbac2de";
          };
          bright = {
            black = "0x585b70"; red = "0xf38ba8"; green = "0xa6e3a1"; yellow = "0xf9e2af";
            blue = "0x89b4fa"; magenta = "0xf5c2e7"; cyan = "0x94e2d5"; white = "0xa6adc8";
          };
        };
      in if isLightTheme then lightColors else darkColors;
    };
  };


  # TODO: Put user-installed binaries here if you want HM to own them (optional)
  # Fonts
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    # Google Fonts (includes Michroma)
    google-fonts
    ];

  # First HM version for this user config; bump only if you understand the migration notes.
  home.stateVersion = "24.11";
}

