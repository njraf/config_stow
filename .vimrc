" Options
set nocompatible
set number
set relativenumber
set ruler
set title
set linebreak
set noerrorbells
set autoindent
set smartindent
set incsearch
set smartcase
set hlsearch
set ignorecase
set laststatus=2
set foldmethod=syntax
set foldlevelstart=99 " prevent autofold when opening a file for the first time
set cursorline
set wildmenu
set undofile
set undodir=~/.vim/undo
set autoread
set noswapfile
set showcmd
set scrolloff=5
set path=.,,**

set autocomplete
set completeopt-=preview " was set for a plugin.

set viewoptions=folds,cursor

filetype plugin on
syntax enable

" netrw configs
let g:netrw_browse_split=4 " open the selected file with <CR> in the previous window
let g:netrw_bufsettings='noma nomod nu nowrap ro nobl rnu'
let g:netrw_liststyle=3

" Command aliases
command Q q
command W w
command Wq wq
command WQ wq
command Wa wa
command WA wa
command Wqa wqa
command WQa wqa
command WQA wqa
command Qa qa
command QA qa

let mapleader = " "

" function to bind grep
function! Grep(str = "")
	let l:pattern = a:str == "" ? input('Grep for:') : a:str
	if !empty(l:pattern)
		execute 'silent! vimgrep /' . escape(l:pattern, '/') . '/gj **/*'
		copen
		let id = matchadd('Search', '\c' . escape(l:pattern, '/'))
	endif
endfunction
nnoremap <silent> <leader>gg :call Grep()<CR>
" grep word under cursor
nnoremap <silent> <leader>gw :call Grep(expand('<cword>'))<CR>
nnoremap <silent> <leader>gW :call Grep('\<' . expand('<cword>') . '\>')<CR>

" function to bind find
function! Find(str = "")
	let l:pattern = a:str == "" ? input('Find:') : a:str
	if !empty(l:pattern)
		execute 'silent! vimgrep /\%1l/j **/*' . escape(l:pattern, '/\') . '*'
		copen
	endif
endfunction
nnoremap <silent> <leader>ff :call Find()<CR>
" grep word under cursor
nnoremap <silent> <leader>fw :call Find(expand('<cword>'))<CR>

" switch between c++ header and source files
function! SwitchSource()
	if (expand("%:e") == "c" || expand("%:e") == "cpp" || expand("%:e") == "cc")
		find %:t:r.h
	else
		if (filereadable(expand("%:t:r") . ".c") != 0)
			find %:t:r.c
		elseif (filereadable(expand("%:t:r") . ".cpp") != 0)
			find %:t:r.cpp
		elseif (filereadable(expand("%:t:r") . ".cc") != 0)
			find %:t:r.cc
		endif
	endif
endfunction
nnoremap <silent> <leader>ch :call SwitchSource()<CR>

" Build a statusline showing all active and hidden buffers
function! StatusLine()
  let l:buffers = []

  for l:bufnr in range(1, bufnr('$'))
    " Skip unlisted buffers (e.g. netrw, help, quickfix)
    if !buflisted(l:bufnr)
      continue
    endif

    let l:name = bufname(l:bufnr)
    let l:label = empty(l:name) ? '[No Name]' : fnamemodify(l:name, ':t')

    " Mark the current buffer distinctly
    if l:bufnr == bufnr('%')
      let l:label = '%#Folded#' . l:label . '%#StatusLine#'
    endif

    " Append a '+' if the buffer has unsaved changes
    if getbufvar(l:bufnr, '&modified')
      let l:label .= '+'
    endif

    call add(l:buffers, l:label)
  endfor

  return '%#StatusLine#' . join(l:buffers, '  │  ') . '%=%l:%c          %P'
endfunction

" Attach the function to the statusline
set statusline=%!StatusLine()

" toggle a file explorer in a vertical split
nnoremap <silent> <leader>e :20Lexplore<CR>

" Custom commands "
" Use Esc to stop highlighting and close quickfix menu
nnoremap <silent> <Esc> <Cmd>:noh<CR>:cclose<CR>
" disable Ex mode and command history
map q: <Nop>
nnoremap Q <Nop>
" buffer navigation
nnoremap <silent> <C-l> :bn<CR>
nnoremap <silent> <C-h> :bp<CR>
nnoremap <leader>b :ls<CR>:b 
nnoremap <silent> <leader>d :bp\|:bd #<CR>
" ctrl-S save
nnoremap <silent> <C-s> :w<CR>
inoremap <silent> <C-s> <Esc>:w<CR>

" navigate quickfix menu
nnoremap <silent> <C-j> :cn<CR>
nnoremap <silent> <C-k> :cp<CR>

" close all windows
nnoremap <silent> <leader>qq :qa<CR>
" quit current buffer
nnoremap <silent> <leader>qw :q<CR>
" close close window next to current window
map <silent> <leader>qh <C-w>h :q<CR>
map <silent> <leader>qj <C-w>j :q<CR>
map <silent> <leader>qk <C-w>k :q<CR>
map <silent> <leader>ql <C-w>l :q<CR>

" Auto commands "
au BufWinLeave * silent! mkview
au BufWinEnter * silent! loadview
" remove [No Name files when they are no longer visible]
au BufEnter * if bufname('%') == '' |  setlocal bufhidden=wipe | endif

" Color scheme
colorscheme desert

" Ultisnips
let g:UltiSnipsListSnippets="<C-l>"
let g:UltiSnipsExpandTrigger="<C-g>"
"let g:UltiSnipsJumpForward="<c-j>"
"let g:UltiSnipsJumpBackward="<c-k>"
"let g:UltiSnipsEditSplit="vertical"

" YouCompleteMe
"let g:ycm_enable_inlay_hints = 1
let g:ycm_autoclose_preview_window_after_completion = 1
"let g:ycm_add_preview_to_completeopt = 0

