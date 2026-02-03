" Options
set number
set relativenumber
set ruler
set title
set linebreak
set noerrorbells
"set smartindent
set autoindent
set incsearch
set smartcase
set hlsearch
set ignorecase
set laststatus=2
set foldmethod=indent " allows folding blocks of code identified by indent
set foldlevelstart=99 " prevent autofold when opening a file for the first time
set path=.,,**/src/**,**/include/**

" netrw configs
let g:netrw_browse_split=4 " open the selected file with <CR> in the previous window
let g:netrw_bufsettings='noma nomod nu nowrap ro nobl rnu'

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
		execute 'silent! vimgrep /' . escape(l:pattern, '/\') . '/gj **/*'
		copen
		let id = matchadd('Search', '\c' . escape(l:pattern, '/\'))
	endif
endfunction
nnoremap <silent> <leader>gg :call Grep()<CR>
" grep word under cursor
nnoremap <silent> <leader>gw :call Grep(expand('<cword>'))<CR>

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

" toggle a file explorer in a vertical split
nnoremap <silent> <leader>e :Lexplore<CR> 999<C-w>< 40<C-w>> 5h

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

au BufWinLeave * silent! mkview
au BufWinEnter * silent! loadview

" Color scheme
:colorscheme desert

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
set completeopt-=preview

