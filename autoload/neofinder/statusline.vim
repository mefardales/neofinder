" neofinder#statusline  -- Global powerline-style statusline for Vim
"
" Provides a rich statusline with:
"   [MODE] | branch | <icon> bufcount | filename | pos | clock
"
" Uses NeoSt* highlight groups set by the active theme.
" Inspired by airline/lualine but pure Vimscript, zero dependencies.
" Works on Vim 8+ and Neovim.

" ---------------------------------------------------------------------------
" Separators (Powerline-style if terminal supports it, else ASCII)
" ---------------------------------------------------------------------------
function! neofinder#statusline#update_separators() abort
  if get(g:neofinder, 'ascii_statusline', 0)
    let s:sep_left  = ''
    let s:sep_right = ''
    let s:sub_left  = '|'
    let s:sub_right = '|'
  else
    let s:sep_left  = get(g:, 'neofinder_sep_left',  "\ue0b0")
    let s:sep_right = get(g:, 'neofinder_sep_right', "\ue0b2")
    let s:sub_left  = get(g:, 'neofinder_sub_left',  "\ue0b1")
    let s:sub_right = get(g:, 'neofinder_sub_right', "\ue0b3")
  endif
endfunction

" Initialize on first load
call neofinder#statusline#update_separators()

" ---------------------------------------------------------------------------
" Git branch detection (cached per buffer change)
" ---------------------------------------------------------------------------
let s:branch_cache = ''
let s:branch_bufnr = -1

function! s:git_branch() abort
  if bufnr('%') == s:branch_bufnr
    return s:branch_cache
  endif
  let s:branch_bufnr = bufnr('%')
  let s:branch_cache = ''

  " Try fugitive first
  if exists('*FugitiveHead')
    let s:branch_cache = FugitiveHead()
    return s:branch_cache
  endif

  " Fall back to git command
  let dir = expand('%:p:h')
  if dir ==# '' | let dir = getcwd() | endif
  let result = systemlist('cd ' . shellescape(dir) . ' && git rev-parse --abbrev-ref HEAD 2>/dev/null')
  if v:shell_error == 0 && !empty(result)
    let s:branch_cache = result[0]
  endif
  return s:branch_cache
endfunction

" ---------------------------------------------------------------------------
" Mode map
" ---------------------------------------------------------------------------
let s:mode_map = {
      \ 'n':      ['NORMAL',  'NeoStMode'],
      \ 'i':      ['INSERT',  'NeoStModeInsert'],
      \ 'v':      ['VISUAL',  'NeoStModeVisual'],
      \ 'V':      ['V-LINE',  'NeoStModeVisual'],
      \ "\<C-v>": ['V-BLOCK', 'NeoStModeVisual'],
      \ 'R':      ['REPLACE', 'NeoStModeReplace'],
      \ 'c':      ['COMMAND', 'NeoStModeCommand'],
      \ 't':      ['TERMINAL','NeoStModeInsert'],
      \ 's':      ['SELECT',  'NeoStModeVisual'],
      \ 'S':      ['S-LINE',  'NeoStModeVisual'],
      \ "\<C-s>": ['S-BLOCK', 'NeoStModeVisual'],
      \ }

function! s:mode_info() abort
  let m = mode()
  return get(s:mode_map, m, ['NORMAL', 'NeoStMode'])
endfunction

" ---------------------------------------------------------------------------
" Build the statusline string (called by Vim's %{} or set statusline=)
" ---------------------------------------------------------------------------
function! neofinder#statusline#build() abort
  let [mode_label, mode_hl] = s:mode_info()
  let branch = s:git_branch()
  let bufcount = len(filter(range(1, bufnr('$')), 'buflisted(v:val)'))

  " Left side
  let s = ''
  " Mode segment
  let s .= '%#' . mode_hl . '#'
  let s .= ' ' . mode_label . ' '
  let s .= '%#NeoStBranch#'

  " Branch segment
  if branch !=# '' && get(g:neofinder, 'sl_branch', 1)
    let s .= ' ' . s:sub_left . ' ' . branch . ' '
  endif

  " Buffer count
  let s .= '%#NeoStInfo#'
  let s .= ' <' . bufcount . ' '

  " File segment
  let s .= '%#NeoStFile#'
  let s .= ' %t'   " filename (tail)

  " Modified / readonly flags
  let s .= '%#NeoStModified#'
  let s .= '%( [+]%)'
  let s .= '%#NeoStReadonly#'
  let s .= '%( [RO]%)'

  " Right side separator
  let s .= '%#NeoStInfo#'
  let s .= '%='   " right-align from here

  " Filetype
  let s .= ' %{&filetype !=# "" ? &filetype : "no ft"} '

  " Position segment
  let s .= '%#NeoStPosition#'
  let s .= ' %l:%c '

  " Percentage / Top/Bot
  let s .= '%#NeoStInfo#'
  let s .= ' %P '

  " Clock segment
  if get(g:neofinder, 'sl_clock', 1)
    let s .= '%#NeoStClock#'
    let s .= ' %{strftime("%H:%M")} '
  endif

  return s
endfunction

" ---------------------------------------------------------------------------
" enable() -- activate the global NeoFinder statusline
" ---------------------------------------------------------------------------
function! neofinder#statusline#enable() abort
  if get(g:neofinder, 'statusline', 1) == 0
    return
  endif
  call neofinder#statusline#update_separators()
  set laststatus=2             " always show statusline
  set cmdheight=1              " command line = 1 row, no wasted space
  set noshowmode               " mode already in statusline
  set noshowcmd                " no partial cmd display eating space
  set display=lastline         " show as much of last line as possible
  set fillchars+=stl:\ ,stlnc:\ ,vert:\│  " clean separators
  set statusline=%!neofinder#statusline#build()

  " Force statusline to update on mode change and resize
  augroup NeoFinderStatusline
    autocmd!
    autocmd InsertEnter,InsertLeave * redrawstatus
    autocmd CmdlineEnter,CmdlineLeave * redrawstatus
    autocmd BufEnter,BufWritePost * let s:branch_bufnr = -1 | redrawstatus
    autocmd ModeChanged * redrawstatus
    autocmd VimResized * redrawstatus
  augroup END
endfunction

" ---------------------------------------------------------------------------
" disable() -- restore Vim's default statusline
" ---------------------------------------------------------------------------
function! neofinder#statusline#disable() abort
  set statusline=
  augroup NeoFinderStatusline
    autocmd!
  augroup END
endfunction

" ---------------------------------------------------------------------------
" toggle() -- toggle on/off
" ---------------------------------------------------------------------------
function! neofinder#statusline#toggle() abort
  if &statusline =~# 'neofinder#statusline'
    call neofinder#statusline#disable()
    set laststatus=0
  else
    call neofinder#statusline#enable()
  endif
endfunction
