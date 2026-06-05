{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withRuby = false;
    withPython3 = false;

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

    initLua = ''
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
      vim.opt.cursorline = true
      vim.opt.mouse = "a"
      vim.opt.listchars = { tab = "→ ", space = "·", nbsp = "␣", trail = "•", eol = "¶", precedes = "«", extends = "»" }
      vim.opt.clipboard:append("unnamedplus")
      vim.opt.spell = true
      vim.opt.spelllang = "en_us"

      -- Markdown: fold by heading/section using Treesitter
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function()
          vim.opt_local.foldmethod = "expr"
          vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
          vim.opt_local.foldenable = true
        end,
      })

      -- Treesitter highlighting: parser-driven syntax highlighting (richer
      -- than the regex-based default). Leaving `indent` off — it's still
      -- buggy in several languages (python, yaml).
      require'nvim-treesitter.configs'.setup {
        highlight = { enable = true },
      }

      -- Sticky scroll: pin enclosing scopes (functions, classes, YAML keys,
      -- etc.) to the top of the window as you scroll deeper. Same idea as
      -- Zed/VS Code's "Sticky Scroll". `mode = 'topline'` matches Zed's
      -- "scrolled past" feel; switch to 'cursor' if you'd rather it track
      -- the cursor instead of the viewport.
      require'treesitter-context'.setup {
        enable = true,
        max_lines = 5,
        mode = 'topline',
        trim_scope = 'outer',
      }

      -- Fish: expand tabs to spaces. Fish renders raw \t in the commandline
      -- as the Unicode glyph ␉ (U+2409) and wrap-indents each line to the
      -- column of the opening quote, which mangles Alt-E multiline edits.
      -- Using spaces sidesteps the issue entirely.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "fish",
        callback = function()
          vim.opt_local.expandtab = true
          vim.opt_local.tabstop = 2
          vim.opt_local.shiftwidth = 2
          vim.opt_local.softtabstop = 2
        end,
      })

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
      nvim-treesitter.withAllGrammars  # parsers (also makes vim.treesitter.foldexpr work for markdown)
      nvim-treesitter-context          # sticky scroll: pin parent scopes at top of window
    ];
  };
}
