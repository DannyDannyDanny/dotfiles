{ pkgs, lib, config, ... }:
{
  programs.home-manager.enable = true;

  # Import neovim configuration
  imports = [ ../../neovim.nix ];

  # ZeroTier SSH aliases — installed at ACTIVATION from a local-only plaintext
  # drop-in. For these to resolve, ~/.ssh/config must include:
  #   Include ~/.ssh/config.d/*
  # near the top (before any host-specific blocks).
  #
  # The fleet's host names + ZeroTier addresses are topology and live ONLY in the
  # local file (and the private homelab repo) — never in this public repo. Place
  # the Host blocks in ~/dotfiles/lib/zerotier-ssh.local; absent it this is a
  # no-op. Done at activation (not via home.file) because a flake build cannot
  # read a gitignored file — flakes exclude untracked files from the source.
  home.activation.zerotierSshAliases = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    _zt_src="$HOME/dotfiles/lib/zerotier-ssh.local"
    if [ -r "$_zt_src" ]; then
      run mkdir -p "$HOME/.ssh/config.d"
      run install -m600 "$_zt_src" "$HOME/.ssh/config.d/zerotier"
    fi
  '';

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

      # Resize pane shortcuts
      bind -r H resize-pane -L 10
      bind -r J resize-pane -D 10
      bind -r K resize-pane -U 10
      bind -r L resize-pane -R 10

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
      # tmux-resurrect: prefix + Ctrl-s saves, prefix + Ctrl-r restores.
      # Snapshot lives at ~/.tmux/resurrect/last (window layout, working
      # dirs, pane contents if enabled). Survives force-quits / reboots
      # / kernel panics.
      #
      # @resurrect-processes: programs to restart on restore. Default
      # list covers vim/emacs/less/top/etc. but NOT nvim, claude, or
      # ssh. The "~name->cmd" form re-runs the original argv; bare
      # names match argv-less invocations. Without this, restored panes
      # come back as plain fish prompts in the right directory.
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-strategy-nvim 'session'
          set -g @resurrect-processes 'nvim "~nvim->nvim *" claude "~claude->claude --continue" ssh "~ssh->ssh *"'
        '';
      }
      # tmux-continuum: auto-saves every 15min and auto-restores on
      # tmux server start. With this, the next force-quit just costs
      # you up to 15min of recent terminal activity, not the whole
      # workspace.
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '15'
        '';
      }
    ];
  };

  # Git configuration
  programs.git = {
    enable = true;
    settings = {
      core = {
        editor = "nvim";
      };
      alias = {
        "tidy" = "!bash ~/dotfiles/scripts/git-cleanup-branches.sh";
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
    DBT_USER = "DNTH"; # used by work dbt pipelines (leap/*-data-pipelines reference it in models)
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # Add faf script to PATH
  home.file.".local/bin/faf" = {
    source = ../../../scripts/f-around-firefox/faf.py;
    executable = true;
  };

  # Palette fragments: synced to system appearance (see scripts/alacritty-sync-system-theme.sh).
  xdg.configFile."alacritty/catppuccin-latte-colors.toml".source =
    ../../../assets/alacritty/catppuccin-latte-colors.toml;
  xdg.configFile."alacritty/catppuccin-mocha-colors.toml".source =
    ../../../assets/alacritty/catppuccin-mocha-colors.toml;

  # Zed: settings.json is a read-only symlink to assets/zed/settings.json.
  # To change a setting, edit the asset file and rebuild — editing via Zed's
  # UI will fail because the target is in the nix store.
  xdg.configFile."zed/settings.json".source = ../../../assets/zed/settings.json;

  # Alacritty: base config + imported active-colors.toml (updated without rebuild)
  programs.alacritty = {
    enable = true;
    settings = {
      general = {
        live_config_reload = true;
        import = [ "${config.xdg.configHome}/alacritty/active-colors.toml" ];
      };
      window = {
        padding = { x = 8; y = 8; };
        dynamic_padding = true;
        decorations = "buttonless";
        decorations_theme_variant = "None";
        opacity = 1.0;
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
    };
  };

  # Writable copy (not a symlink to the store — cp in the sync script must replace a real file).
  home.activation.alacrittySystemTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    MOCHA="${../../../assets/alacritty/catppuccin-mocha-colors.toml}"
    ACTIVE="${config.xdg.configHome}/alacritty/active-colors.toml"
    $DRY_RUN_CMD mkdir -p "${config.xdg.configHome}/alacritty"
    if [ ! -f "$ACTIVE" ]; then
      $DRY_RUN_CMD cp "$MOCHA" "$ACTIVE"
      $DRY_RUN_CMD chmod 0644 "$ACTIVE"
    fi
    $DRY_RUN_CMD ${pkgs.bash}/bin/bash "${../../../scripts/alacritty-sync-system-theme.sh}" || true
  '';


  # TODO: Put user-installed binaries here if you want HM to own them (optional)
  # Fonts
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    # Zen Browser (Firefox fork; from flake overlay, supports aarch64-darwin)
  ] ++ (lib.optionals (pkgs ? zen-browser) [
    pkgs.zen-browser
  ]) ++ (with pkgs; [
    # Google Fonts (includes Michroma)
    google-fonts

    # Development tools
    ripgrep       # replacement for grep
    fd            # replacement for find
    wget          # downloader
    gh            # github cli tool
    claude-code   # Anthropic agentic coding CLI
    uv            # Python pkg/runner; `uvx` runs the Plane MCP server (self-managed py, GC-safe)
    forgejo-cli   # forgejo/codeberg cli (provides fj)
    git           # version control
    jujutsu       # Git alternative
    gnupg         # GNU privacy guard (GPG)
    coreutils     # GNU core utilities
    openssl       # cryptography swiss army knife
    # busybox     # doesn't run on darwin

    # Utilities
    fastfetch     # system info
    btop          # resource monitor
    zoxide        # directory jumping (cd alternative)
    tldr          # community driven manpage alternative
    fzf           # fuzzy finder
    tree          # list directory contents
    ffmpeg        # video and audio processing
    lz4           # compression tool (needed for reading Firefox session files)
    cowsay        # ascii art cows for fun
    lolcat        # rainbow text for fun
    # vlc           # video player - doesn't build for MacOS

    # Applications
    # (alacritty comes from programs.alacritty above, not this list)
    zed-editor
    code-cursor
    cursor-cli
    cinny-desktop # Matrix client (Tauri wrapper around the Cinny web app)
    dfu-util      # USB DFU firmware flasher (Flipper Zero etc.)
    discord
    mapscii
    mpv
    # uhk-agent  # UHK keyboard configuration GUI + CLI — removed, nixpkgs marks x86_64-linux only TODO
  ]);

  # First HM version for this user config; bump only if you understand the migration notes.
  home.stateVersion = "25.11";
}

