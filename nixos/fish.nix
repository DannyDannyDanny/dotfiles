{ config, pkgs, ... }:

{
  programs.fish = {
    enable = true;
    shellAliases = {
      theme = "bash ~/dotfiles/scripts/theme.sh";
      music = "mpv --no-video --log-file=~/music_history.log \"$(find /mnt/c/Users/DNTH/Music/ -type f \\( -name '*.mp3' -o -name '*.wav' -o -name '*.flac' -o -name '*.m4a' -o -name '*.ogg' \\) | fzf)\"";
      weather = "curl wttr.in/?T";
    };
    interactiveShellInit = ''
      fish_vi_key_bindings
      set fish_greeting 🐟: (set_color yellow; date +%T; set_color green; date --iso-8601 2>/dev/null; or date +%F; set_color normal)

      # name: Default
      # author: Lily Ballard
      # edits: DannyDannyDanny
      # ref: stackoverflow.com/a/61262358/5684214

      function fish_prompt --description 'Write out the prompt'
        set -l last_pipestatus $pipestatus
        set -lx __fish_last_status $status # Export for __fish_print_pipestatus.
        set -l normal (set_color normal)
        set -q fish_color_status
        or set -g fish_color_status red

        # Color the prompt differently when we're root
        set -l color_cwd $fish_color_cwd
        set -l suffix '>'
        if functions -q fish_is_root_user; and fish_is_root_user
            if set -q fish_color_cwd_root
                set color_cwd $fish_color_cwd_root
            end
            set suffix '#'
        end

        # Write pipestatus
        # If the status was carried over (if no command is issued or if `set` leaves the status untouched), don't bold it.
        set -l bold_flag --bold
        set -q __fish_prompt_status_generation; or set -g __fish_prompt_status_generation $status_generation
        if test $__fish_prompt_status_generation = $status_generation
            set bold_flag
        end
        set __fish_prompt_status_generation $status_generation
        set -l status_color (set_color $fish_color_status)
        set -l statusb_color (set_color $bold_flag $fish_color_status)
        set -l prompt_status (__fish_print_pipestatus "[" "]" "|" "$status_color" "$statusb_color" $last_pipestatus)
        set -l nix_shell_info (
          if test -n "$IN_NIX_SHELL"
            echo -n "🐚 "
          end
        )

        echo -n -s (prompt_login)' ' (set_color $color_cwd) (prompt_pwd) $normal (fish_vcs_prompt) $normal " "$prompt_status $nix_shell_info $suffix " "
      end

    '';

    shellInit = ''
      if test -d /opt/homebrew/bin
        fish_add_path -g /opt/homebrew/bin /opt/homebrew/sbin
      end

      # Set default editor
      set -gx EDITOR nvim
      set -gx VISUAL nvim

      zoxide init fish | source
    '';
  };

  programs.bash = {
    interactiveShellInit = ''
      # the first arguement in the if statement check that the parent process is not a fish shell.
      # this allows spawning a bash shell inside a fish shell without the inner-most bash shell launching a fish shell
      # however this also means that nix-shell starts a bash shell unless you use `nix-shell [args] --run fish`
      # or run `fish` as the first command when entering nix-shell

      # Use macOS/BSD-compatible ps flags to detect parent shell
      if [[ $(ps -p "$PPID" -o comm=) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
      then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
      fi
    '';
  };
}
