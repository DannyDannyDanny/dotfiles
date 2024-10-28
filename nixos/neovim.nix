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

        " relative line numbering when leaving insert mode
        set relativenumber
        autocmd InsertEnter * :set number norelativenumber
        autocmd InsertLeave * :set nonumber relativenumber

        " netrw (dir listing) settings
        let g:netrw_liststyle = 3
        let g:netrw_banner = 0
        let g:netrw_browse_split = 3
        let g:netrw_winsize = 25  " % of page

	set listchars=tab:→\ ,space:·,nbsp:␣,trail:•,eol:¶,precedes:«,extends:»
	set clipboard+=unnamedplus

	" Replace-all is aliased to S.
        nnoremap S :%s//g<Left><Left>

        " spellcheck
        set spell spelllang=en_us
        setlocal spell! spelllang=en_us
      '';
      # vimPlugins inspired from Alexnortung
      # https://discourse.nixos.org/t/neovim-no-longer-uses-config-or-plugins/13399/4
      packages.nix = with pkgs.vimPlugins; {
        start = [
          vim-surround  # shortcuts for setting () {} etc.
          # coc-nvim coc-git coc-highlight coc-python coc-rls coc-vetur coc-vimtex coc-yaml coc-html coc-json # auto completion
          vim-nix       # nix highlight
          vimtex        # latex stuff
          fzf-vim       # fuzzy finder through vim
          nerdtree      # file structure inside nvim
          rainbow       # color parenthesis
	  gruvbox-nvim  # theme
          goyo-vim      # write prose
          limelight-vim # prose paragraph highlighter
        ];
        opt = [];
      };
    };
  };
}
 
