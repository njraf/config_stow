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
nnoremap <leader>gg :call Grep()<CR>
" grep word under cursor
nnoremap <leader>gw :call Grep(expand('<cword>'))<CR>

" function to bind find
function! Find(str = "")
	let l:pattern = a:str == "" ? input('Find:') : a:str
	if !empty(l:pattern)
		execute 'silent! vimgrep /\%1l/j **/*' . escape(l:pattern, '/\') . '*'
		copen
	endif
endfunction
nnoremap <leader>ff :call Find()<CR>
" grep word under cursor
nnoremap <leader>fw :call Find(expand('<cword>'))<CR>

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
nnoremap <leader>ch :call SwitchSource()<CR>

" toggle a file explorer in a vertical split
nnoremap <leader>e :Lexplore<CR> 999<C-w>< 40<C-w>> 5h

" Custom commands "
" Use Esc to stop highlighting and close quickfix menu
nnoremap <Esc> <Cmd>:noh<CR>:cclose<CR>
" disable Ex mode and command history
map q: <Nop>
nnoremap Q <Nop>
" buffer navigation
nnoremap <C-l> :bn<CR>
nnoremap <C-h> :bp<CR>
nnoremap <leader>b :ls<CR>:b 
nnoremap <leader>d :bp\|:bd #<CR>
" ctrl-S save
nnoremap <C-s> :w<CR>
inoremap <C-s> <Esc>:w<CR>

" navigate quickfix menu
nnoremap <C-j> :cn<CR>
nnoremap <C-k> :cp<CR>

" close all windows
nnoremap <leader>qq :qa<CR>
" quit current buffer
nnoremap <leader>qw :q<CR>
" close close window next to current window
map <leader>qh <C-w>h :q<CR>
map <leader>qj <C-w>j :q<CR>
map <leader>qk <C-w>k :q<CR>
map <leader>ql <C-w>l :q<CR>

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

