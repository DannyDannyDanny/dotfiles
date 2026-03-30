{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;

    # VimScript settings (options that have no Lua equivalent or are simpler in vim)
    extraConfig = ''
      set title
      set nohlsearch
      set number
      let mapleader=","

      colorscheme catppuccin

      " netrw (dir listing) settings
      let g:netrw_liststyle = 3
      let g:netrw_banner = 0
      let g:netrw_browse_split = 3
      let g:netrw_winsize = 25
    '';

    extraLuaConfig = ''
      -- Auto-detect system theme (dark/light) from marker file
      local config_file = os.getenv("HOME") .. "/.local/share/nvim_color_scheme"
      local f = io.open(config_file, "r")
      if f then
        local theme = f:read("*l")
        f:close()
        if theme then
          theme = theme:gsub("^%s+", ""):gsub("%s+$", "")
        end
        if theme == "dark" or theme == "light" then
          vim.opt.background = theme
        else
          vim.notify("nvim_color_scheme: expected 'light' or 'dark', got: " .. tostring(theme), vim.log.levels.WARN)
        end
      end

      -- General options
      vim.opt.mouse = "a"
      vim.opt.listchars = { tab = "→ ", space = "·", nbsp = "␣", trail = "•", eol = "¶", precedes = "«", extends = "»" }
      vim.opt.clipboard:append("unnamedplus")
      vim.opt.spell = true
      vim.opt.spelllang = "en_us"

      -- Keymaps
      vim.keymap.set("n", "S", ":%s//g<Left><Left>", { desc = "Replace all" })
      vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "Save file" })
    '';

    plugins = with pkgs.vimPlugins; [
      vim-surround    # shortcuts for setting () {} etc.
      vim-gitgutter   # git diff in sign column
      vim-nix         # nix highlight
      fzf-lua         # fuzzy finder through lua
      nerdtree        # file structure inside nvim
      rainbow         # color parenthesis
      catppuccin-nvim # theme
      goyo-vim        # write prose
      limelight-vim   # prose paragraph highlighter
    ];
  };
}
