{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    configure = {
      customRC = ''
        set title
        set go=a
        set mouse=a
        set nohlsearch
        set number
        let mapleader=","

        lua << EOF
          local config_file = os.getenv("HOME")..'/.local/share/nvim_color_scheme'
          local f=io.open(config_file, "r")
          if f~=nil then 
              local system_theme = f:read()
              -- f:close()
              io.close(f)
              if system_theme == 'dark' then
                  vim.cmd("set bg=dark")
              elseif system_theme == 'light' then
                  vim.cmd("set bg=light")
              else
                  print('warning: expected value "light" or "dark"')
                  print('  got:', system_theme)
                  print('  expected path:', file)
              end
          else 
              print('warning: nvim color scheme not found')
              print('  expected path:', file)
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
      # vimPlugins inspired from Alexnortung
      # https://discourse.nixos.org/t/neovim-no-longer-uses-config-or-plugins/13399/4
      packages.nix = with pkgs.vimPlugins; {
        start = [
          vim-surround  # shortcuts for setting () {} etc.
          vim-gitgutter # git diff in sign column
          # vim-airline   # nice and light status bar # doesn't work nicely with tmux
          # coc-nvim coc-git coc-highlight coc-python coc-rls coc-vetur coc-vimtex coc-yaml coc-html coc-json # auto completion
          vim-nix       # nix highlight
          vimtex        # latex stuff
          fzf-vim       # fuzzy finder through vim
          nerdtree      # file structure inside nvim
          rainbow       # color parenthesis
          # gruvbox-nvim  # theme
          catppuccin-nvim # theme
          goyo-vim      # write prose
          limelight-vim # prose paragraph highlighter
        ];
        opt = [];
      };
    };
  };
}
 
