" Options
set number
set relativenumber
set ruler
set smartindent
set incsearch
set smartcase
set hlsearch
set ignorecase
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

" Custom commands
nnoremap <Esc> <Cmd>:noh<CR>

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

