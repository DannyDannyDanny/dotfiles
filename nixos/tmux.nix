{ config, pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    clock24 = true;
    # escapeTime = 20;
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

      # extend history
      set -g history-limit 100000

      # set vi keybindings
      setw -g mode-keys vi
      bind -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "xsel -i --clipboard"

      # reduce escape time
      set -sg escape-time 20

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
      #pkgs.tmuxPlugins.
      pkgs.tmuxPlugins.catppuccin
    ];
  };
}
