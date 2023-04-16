let mapleader =","

" set termguicolors

if ! filereadable(system('echo -n "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/autoload/plug.vim"'))
	echo "Downloading junegunn/vim-plug to manage plugins..."
	silent !mkdir -p ${XDG_CONFIG_HOME:-$HOME/.config}/nvim/autoload/
	silent !curl "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" > ${XDG_CONFIG_HOME:-$HOME/.config}/nvim/autoload/plug.vim
	autocmd VimEnter * PlugInstall
endif

call plug#begin(system('echo -n "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/plugged"'))
Plug 'tpope/vim-surround'     " surround for parentheses, brackets, quotes, XML tags etc
Plug 'tpope/vim-fugitive'     " git helper
Plug 'preservim/nerdtree'     " file tree
Plug 'jreybert/vimagit'       " git diffing with :Magit
Plug 'lukesmithxyz/vimling'   " toggle deadkeys, IPA, prose-mode
Plug 'junegunn/goyo.vim'      " prose mode but better
Plug 'vimwiki/vimwiki'        " take notes in vimwiki
Plug 'michal-h21/vimwiki-sync'  " sync notes to git repo
Plug 'itchyny/calendar.vim'     " integrate calendar into vimwiki (todo)
Plug 'vim-airline/vim-airline'  " status bar
Plug 'tpope/vim-commentary'   " comment out word / line with 'gc'
Plug 'ap/vim-css-color'       " show css colors
Plug 'editorconfig/editorconfig-vim'    " editor-config extension for vim
Plug 'scrooloose/syntastic'		" syntax checker
" Plug 'airblade/vim-gitgutter'		" show git diff insertions / deletions
" Plug 'junegunn/vim-emoji'       " emoji autocomplete + emojis in gitgutter
Plug 'rrethy/vim-illuminate'		" highlight other uses of the current word under the cursor
" Plug 'jupyter-vim/jupyter-vim'	" one day we'll start using jupyter in vim
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } } " fuzzy-finder
Plug 'ibhagwan/fzf-lua', {'branch': 'main'}
" optional for icon support
Plug 'kyazdani42/nvim-web-devicons'
" for nvim nirvana
Plug 'hkupty/iron.nvim'         " connect to REPLs (i.e. ipython)
Plug 'kana/vim-textobj-user'
Plug 'kana/vim-textobj-line'
Plug 'GCBallesteros/vim-textobj-hydrogen'
Plug 'GCBallesteros/jupytext.vim'
call plug#end()


" show invisibles
set fileencoding=utf-8
set list
set listchars=tab:→\ ,nbsp:␣,trail:•,precedes:«,extends:»

" vim-emoji setup
" set completefunc=emoji#complete
" let g:gitgutter_sign_added = emoji#for('small_blue_diamond')
" let g:gitgutter_sign_modified = emoji#for('small_orange_diamond')
" let g:gitgutter_sign_removed = emoji#for('small_red_triangle')
" let g:gitgutter_sign_modified_removed = emoji#for('collision')


" syntastic recommended settings
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_python_checkers = ['python', 'flake8']
let g:syntastic_python_python_exec = 'python3'
let g:syntastic_rst_checkers=['sphinx']

" nvim nirvana
" Jupytext
let g:jupytext_fmt = 'py'
let g:jupytext_style = 'hydrogen'
" Send cell to IronRepl and move to next cell.
" Depends on the text object defined in vim-textobj-hydrogen
" You first need to be connected to IronRepl
nmap ]x ctrih/^# %%<CR><CR>
luafile $HOME/.config/nvim/plugins.lua

" python stuff
" let g:python3_host_prog = "$HOME/.venvs/nvim/bin/python"
let g:python4_host_prog = "$HOME/.config/nvim/python"

" VimWiki setup
let g:vimwiki_sync_branch = "main"
let g:vimwiki_sync_commit_message = 'vimwiki: $USER @ $HOST'
let g:sync_taskwarrior = 0
let g:vimwiki_markdown_link_ext = 1   " explicitly add .md extension in vimwiki

let wiki_1 = {}
let wiki_1.name = 'vimwiki_private'
let wiki_1.path = '~/vimwiki/'
let wiki_1.syntax = 'markdown'
let wiki_1.ext = 'md'
let wiki_1.automatic_nested_syntaxes = 1

let wiki_2 = {}
let wiki_2.name = 'methodology_public'
let wiki_2.path = '~/methodology/'
let wiki_2.syntax = 'markdown'
let wiki_2.ext = 'md'
let wiki_2.automatic_nested_syntaxes = 1

let wiki_3 = {}
let wiki_3.name = 'taiga_admin_private'
let wiki_3.path = '~/administration/'
let wiki_3.syntax = 'markdown'
let wiki_3.ext = 'md'
let wiki_3.automatic_nested_syntaxes = 1

let wiki_4 = {}
let wiki_4.name = 'dotfiles_public'
let wiki_4.path = '~/dotfiles/'
let wiki_4.syntax = 'markdown'
let wiki_4.ext = 'md'
let wiki_4.automatic_nested_syntaxes = 1

let g:vimwiki_list = [wiki_1, wiki_2, wiki_3, wiki_4]

" calendar setup
let g:calendar_first_day = 'monday'   " set monday as first day of week
let g:calendar_week_number = 1        " add weeknumber

" open new tab with tu - inspired by theniceboy/nvim
noremap tu :tabe<CR>
noremap tU :tab split<CR>

" configs below are from LukeSmithxyz/LARBS
set title
set bg=light
set go=a
set mouse=a
set nohlsearch
set clipboard+=unnamedplus
set noshowmode
set noruler
set laststatus=0
set noshowcmd

" Some basics:
	nnoremap c "_c
	set nocompatible
	filetype plugin on
	syntax on
	set encoding=utf-8
	set number relativenumber
" Enable autocompletion:
	set wildmode=longest,list,full
" Disables automatic commenting on newline:
	autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o
" Perform dot commands over visual blocks:
	vnoremap . :normal .<CR>
" Goyo plugin makes text more readable when writing prose:
	map <leader>f :Goyo \| set bg=light \| set linebreak<CR>
" Spell-check set to <leader>o, 'o' for 'orthography':
	map <leader>o :setlocal spell! spelllang=en_us<CR>
" Splits open at the bottom and right, which is non-retarded, unlike vim defaults.
	set splitbelow splitright

" Nerd tree
	map <leader>n :NERDTreeToggle<CR>
	autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
    if has('nvim')
        let NERDTreeBookmarksFile = stdpath('data') . '/NERDTreeBookmarks'
    else
        let NERDTreeBookmarksFile = '~/.vim' . '/NERDTreeBookmarks'
    endif

" vimling:
	nm <leader><leader>d :call ToggleDeadKeys()<CR>
	imap <leader><leader>d <esc>:call ToggleDeadKeys()<CR>a
	nm <leader><leader>i :call ToggleIPA()<CR>
	imap <leader><leader>i <esc>:call ToggleIPA()<CR>a
	nm <leader><leader>q :call ToggleProse()<CR>

" Shortcutting split navigation, saving a keypress:
	map <C-h> <C-w>h
	map <C-j> <C-w>j
	map <C-k> <C-w>k
	map <C-l> <C-w>l

" Replace ex mode with gq
	map Q gq

" Check file in shellcheck:
	map <leader>s :!clear && shellcheck -x %<CR>

" Open my bibliography file in split
	map <leader>b :vsp<space>$BIB<CR>
	map <leader>r :vsp<space>$REFER<CR>

" Replace all is aliased to S.
	nnoremap S :%s//g<Left><Left>

" Compile document, be it groff/LaTeX/markdown/etc.
	map <leader>c :w! \| !compiler "<c-r>%"<CR>

" Open corresponding .pdf/.html or preview
	map <leader>p :!opout <c-r>%<CR><CR>

" Runs a script that cleans out tex build files whenever I close out of a .tex file.
	autocmd VimLeave *.tex !texclear %

" Ensure files are read as what I want:
	let g:vimwiki_ext2syntax = {'.Rmd': 'markdown', '.rmd': 'markdown','.md': 'markdown', '.markdown': 'markdown', '.mdown': 'markdown'}
	autocmd BufRead,BufNewFile /tmp/calcurse*,~/.calcurse/notes/* set filetype=markdown
	autocmd BufRead,BufNewFile *.ms,*.me,*.mom,*.man set filetype=groff
	autocmd BufRead,BufNewFile *.tex set filetype=tex

" Save file as sudo on files that require root permission
	cnoremap w!! execute 'silent! write !sudo tee % >/dev/null' <bar> edit!

" Enable Goyo by default for mutt writing
  autocmd BufRead,BufNewFile /tmp/neomutt* let g:goyo_width=80
  autocmd BufRead,BufNewFile /tmp/neomutt* :Goyo | set bg=light
  autocmd BufRead,BufNewFile /tmp/neomutt* map ZZ :Goyo\|x!<CR>
  autocmd BufRead,BufNewFile /tmp/neomutt* map ZQ :Goyo\|q!<CR>

" Automatically deletes all trailing whitespace and newlines at end of file on save. & reset cursor position
  autocmd BufWritePre * let currPos = getpos(".")
  autocmd BufWritePre * %s/\s\+$//e
  autocmd BufWritePre * %s/\n\+\%$//e
  autocmd BufWritePre *.[ch] %s/\%$/\r/e
  autocmd BufWritePre * cal cursor(currPos[1], currPos[2])

" When shortcut files are updated, renew bash and ranger configs with new material:
	autocmd BufWritePost bm-files,bm-dirs !shortcuts
" Run xrdb whenever Xdefaults or Xresources are updated.
	autocmd BufRead,BufNewFile Xresources,Xdefaults,xresources,xdefaults set filetype=xdefaults
	autocmd BufWritePost Xresources,Xdefaults,xresources,xdefaults !xrdb %
" Recompile dwmblocks on config edit.
	autocmd BufWritePost ~/.local/src/dwmblocks/config.h !cd ~/.local/src/dwmblocks/; sudo make install && { killall -q dwmblocks;setsid -f dwmblocks }

" Turns off highlighting on the bits of code that are changed
" so the line that is changed is highlighted but the actual text
" that has changed stands out on the line and is readable.
if &diff
    highlight! link DiffText MatchParen
endif

" Function for toggling the bottom statusbar:
let s:hidden_all = 0
function! ToggleHiddenAll()
    if s:hidden_all  == 0
        let s:hidden_all = 1
        set noshowmode
        set noruler
        set laststatus=0
        set noshowcmd
    else
        let s:hidden_all = 0
        set showmode
        set ruler
        set laststatus=2
        set showcmd
    endif
endfunction
nnoremap <leader>h :call ToggleHiddenAll()<CR>

" Load command shortcuts generated from bm-dirs and bm-files via shortcuts script.
" Here leader is ";".
" So ":vs ;cfz" will expand into ":vs /home/<user>/.config/zsh/.zshrc"
" if typed fast without the timeout.
" source ~/.config/nvim/shortcuts.vim
