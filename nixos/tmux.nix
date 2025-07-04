{ config, pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    clock24 = true;
    escapeTime = 20;
    keyMode = "vi";
    historyLimit = 100000;
    baseIndex = 1;

    extraConfig = ''
      # remap prefix from ^+B to alt-f
      unbind C-b
      set -g prefix M-f
      bind M-f send-prefix

      # nvim 'checkhealth' advice
      set-option -g focus-events on
      set-option -sa terminal-overrides ',xterm-256color:RGB'
      set-option -g default-terminal "screen-256color"

      # enable mouse support for switching panes/windows
      set -g mouse on

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

      # server-tmux only:
      # fix ssh agent when tmux is detached
      # setenv -g SSH_AUTH_SOCK $HOME/.ssh/ssh_auth_sock
    '';
    plugins = [
      pkgs.tmuxPlugins.catppuccin
    ];
  };
}
