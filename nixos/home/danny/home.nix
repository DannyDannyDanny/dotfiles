{ pkgs, ... }:
{
  # TODO: remove next two lines from here or from flake.nix
  # home.username = "danny";
  # home.homeDirectory = "/Users/danny";

  programs.home-manager.enable = true;

  # Import neovim configuration
  imports = [ ../../neovim.nix ];

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

      # Enable mouse with smooth scrolling
      set -g mouse on
      # Override the default wheel bindings that cause 5-line jumps
      unbind -T copy-mode WheelUpPane
      unbind -T copy-mode WheelDownPane
      unbind -T copy-mode-vi WheelUpPane
      unbind -T copy-mode-vi WheelDownPane
      # Bind smooth scrolling (1 line at a time)
      bind -T copy-mode WheelUpPane send-keys -X scroll-up
      bind -T copy-mode WheelDownPane send-keys -X scroll-down
      bind -T copy-mode-vi WheelUpPane send-keys -X scroll-up
      bind -T copy-mode-vi WheelDownPane send-keys -X scroll-down
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
    settings = {
      core = {
        editor = "nvim";
      };
    };
  };

  # direnv (user-level tool)
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Firefox
  programs.firefox = {
    enable = true;
    profiles.default = {
      settings = {
        "devtools.debugger.remote-enabled" = true;
        "devtools.debugger.remote-port" = 6000;
        "devtools.chrome.enabled" = true;
        "devtools.debugger.prompt-connection" = false;
      };
    };
  };

  # Environment variables (user-level)
  home.sessionVariables = {
    DBT_USER = "DNTH"; # TODO: remove this
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # Add faf script to PATH
  home.file.".local/bin/faf" = {
    source = ../../../scripts/f-around-firefox/faf.py;
    executable = true;
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
        startup_mode = "Maximized";
        option_as_alt = "Both";
      };
      scrolling = { history = 10000; multiplier = 1; };
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

    # Development tools
    ripgrep       # replacement for grep
    fd            # replacement for find
    wget          # downloader
    # azure-cli   # TODO: remove this Azure cli tool
    gh            # github cli tool
    git           # version control
    jujutsu       # Git alternative
    gnupg         # GNU privacy guard (GPG)
    coreutils     # GNU core utilities
    openssl       # cryptography swiss army knife
    # busybox     # doesn't run on darwin

    # Utilities
    neofetch      # system info
    btop          # resource monitor
    zoxide        # directory jumping (cd alternative)
    tldr          # community driven manpage alternative
    fzf           # fuzzy finder
    tree          # list directory contents
    ffmpeg        # video and audio processing
    lz4           # compression tool (needed for reading Firefox session files)
    cowsay        # ascii art cows for fun
    lolcat        # rainbow text for fun
    vlc           # video player

    # Applications
    # alacritty   # TODO: configured via programs.alacritty above, so not needed here
    # warp-terminal # TODO: Bloat
    # vscodium     # TODO: Bloat
    # zed-editor   # TODO: Bloat
    code-cursor
    cursor-cli
    discord
    mapscii
    mpv
  ];

  # First HM version for this user config; bump only if you understand the migration notes.
  home.stateVersion = "25.11";
}

