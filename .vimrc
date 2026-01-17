" Options
set number
set relativenumber
set ruler
set smartindent
set incsearch
set smartcase
set hlsearch
set ignorecase
set laststatus=2
"set foldmethod=indent "allows folding blocks of code identified by indent
"level; auto folds everything on file open

" Command aliases
:command Q q
:command W w
:command Wq wq
:command WQ wq
:command Wa wa
:command WA wa
:command Wqa wqa
:command WQa wqa
:command WQA wqa
:command Qa qa
:command QA qa

let mapleader = " "

" Custom commands "
" Use Esc to stop highlighting
nnoremap <Esc> <Cmd>:noh<CR>
" disable Ex mode and command history
map q: <Nop>
nnoremap Q <Nop>
" buffer navigation
nnoremap <C-l> :bn<CR>
nnoremap <C-h> :bp<CR>
nnoremap <leader>b :ls<CR>:b 
" ctrl-S save
nnoremap <C-s> :w<CR>
inoremap <C-s> <Esc>:w<CR>

au BufWinLeave * mkview
au BufWinEnter * silent loadview

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

