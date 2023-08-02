let mapleader =","

" show invisibles
set fileencoding=utf-8
set list
set listchars=tab:→\ ,nbsp:␣,trail:•,precedes:«,extends:»

" calendar setup
let g:calendar_first_day = 'monday'   " set monday as first day of week
let g:calendar_week_number = 1        " add weeknumber

" configs below are from LukeSmithxyz/LARBS
set title
set bg=light
set go=a
set mouse=a
set nohlsearch

" clipboard + file name/path yanking
set clipboard+=unnamedplus
" yank file name
nmap yf :let @+ = expand("%")<cr>
" yank file full path
nmap yp :let @+ = expand("%:p")<cr>


" relative line numbering when leaving insert mode
set relativenumber
autocmd InsertEnter * :set number norelativenumber
autocmd InsertLeave * :set nonumber relativenumber

" netrw (dir listing) settings
let g:netrw_liststyle = 3
let g:netrw_banner = 0
let g:netrw_browse_split = 3
let g:netrw_winsize = 25  " % of page

" Some basics:
	nnoremap c "_c
	set nocompatible
	filetype plugin on
	syntax on
	set encoding=utf-8
" Enable autocompletion:
	set wildmode=longest,list,full
" Disables automatic commenting on newline:
	autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o
" Perform dot commands over visual blocks:
	vnoremap . :normal .<CR>
" Spell-check set to <leader>o, 'o' for 'orthography':
	map <leader>o :setlocal spell! spelllang=en_us<CR>
" Splits open at the bottom and right, which is non-retarded, unlike vim defaults.
	set splitbelow splitright

" Shortcutting split navigation, saving a keypress:
	map <C-h> <C-w>h
	map <C-j> <C-w>j
	map <C-k> <C-w>k
	map <C-l> <C-w>l

" Replace all is aliased to S.
  nnoremap S :%s//g<Left><Left>

" Automatically deletes all trailing whitespace and newlines at end of file on save. & reset cursor position
  autocmd BufWritePre * let currPos = getpos(".")
  autocmd BufWritePre * %s/\s\+$//e
  autocmd BufWritePre * %s/\n\+\%$//e
  autocmd BufWritePre *.[ch] %s/\%$/\r/e
  autocmd BufWritePre * cal cursor(currPos[1], currPos[2])
