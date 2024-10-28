{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    configure = {
      customRC = ''
        set title
        set bg=light
        set go=a
        set mouse=a
        set nohlsearch

        colorscheme gruvbox

        set listchars=tab:→\ ,space:·,nbsp:␣,trail:•,eol:¶,precedes:«,extends:»
        set clipboard+=unnamedplus

        " Replace-all is aliased to S.
        nnoremap S :%s//g<Left><Left>
      '';
      # vimPlugins inspired from Alexnortung
      # https://discourse.nixos.org/t/neovim-no-longer-uses-config-or-plugins/13399/4
      packages.nix = with pkgs.vimPlugins; {
        start = [
          vim-surround # Shortcuts for setting () {} etc.
          # coc-nvim coc-git coc-highlight coc-python coc-rls coc-vetur coc-vimtex coc-yaml coc-html coc-json # auto completion
          vim-nix # nix highlight
          vimtex # latex stuff
          fzf-vim # fuzzy finder through vim
          nerdtree # file structure inside nvim
          rainbow # Color parenthesis
          gruvbox-nvim # theme
        ];
        opt = [];
      };
    };
  };
}
 
