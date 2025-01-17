{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    # package = pkgs.neovim;
    configure = {
      customRC = ''
        set title
        set go=a
        set mouse=a
        set nohlsearch

        lua << EOF
          local hkey_current_user_path = 'HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize'
          local ps_cmd = 'Get-ItemProperty -Path ' .. hkey_current_user_path .. ' -Name AppsUseLightTheme'
          local parent_cmd = 'powershell.exe -Command "' .. ps_cmd .. '"'
          local handle = io.popen(parent_cmd)
          local result = handle:read("*a")
          handle:close()
          local apps_use_light_theme = string.match(result, "AppsUseLightTheme%s*:%s*(%d+)")
          local use_dark_bg = apps_use_light_theme == '0'
          print('use dark:', use_dark_bg)

          if use_dark_bg then
            vim.cmd("set bg=dark")
          else
            vim.cmd("set bg=light")
          end
        EOF

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
 
