" neofinder#preview  -- syntax-highlighted preview window
"
" Opens a vertical split on the right to preview the currently highlighted
" file.  Detects filetype from extension and shebang, enables syntax
" highlighting and indentation, and applies Matrix-themed highlight groups.

let s:preview_bufnr = -1
let s:preview_winid = -1

" ---------------------------------------------------------------------------
" Filetype detection table
" ---------------------------------------------------------------------------
let s:ext_ft_map = {
      \ 'sh':    'sh',       'bash':  'sh',       'zsh':    'zsh',
      \ 'py':    'python',   'pyw':   'python',
      \ 'js':    'javascript', 'mjs': 'javascript', 'cjs': 'javascript',
      \ 'json':  'json',     'jsonc': 'json',
      \ 'yaml':  'yaml',     'yml':   'yaml',
      \ 'ini':   'dosini',   'cfg':   'dosini',   'conf':   'conf',
      \ 'toml':  'toml',
      \ 'vim':   'vim',
      \ 'lua':   'lua',
      \ 'rb':    'ruby',
      \ 'go':    'go',
      \ 'rs':    'rust',
      \ 'c':     'c',        'h':     'c',
      \ 'cpp':   'cpp',      'hpp':   'cpp',      'cc':     'cpp',
      \ 'java':  'java',
      \ 'xml':   'xml',      'html':  'html',     'htm':    'html',
      \ 'css':   'css',
      \ 'md':    'markdown',
      \ 'tf':    'terraform', 'hcl': 'terraform',
      \ 'sql':   'sql',
      \ 'service': 'systemd', 'timer': 'systemd', 'socket': 'systemd',
      \ 'target': 'systemd',  'mount': 'systemd',
      \ }

" ---------------------------------------------------------------------------
" Detect filetype from path and content
" ---------------------------------------------------------------------------
function! s:detect_filetype(path, lines) abort
  " Extension-based
  let ext = fnamemodify(a:path, ':e')
  if has_key(s:ext_ft_map, ext)
    return s:ext_ft_map[ext]
  endif

  " Basename matches
  let base = fnamemodify(a:path, ':t')
  if base ==# 'Dockerfile' || base =~# '^Dockerfile\.'
    return 'dockerfile'
  endif
  if base =~# '^Makefile'
    return 'make'
  endif
  if base =~# '^\.\?nginx' || a:path =~# '/nginx/'
    return 'nginx'
  endif
  if base =~# '\.service$\|\.timer$\|\.socket$\|\.mount$\|\.target$'
    return 'systemd'
  endif
  if a:path =~# '/systemd/' || a:path =~# '/system/'
    return 'systemd'
  endif
  if a:path =~# '/apache2/\|/httpd/'
    return 'apache'
  endif

  " Shebang detection
  if !empty(a:lines)
    let first = a:lines[0]
    if first =~# '^#!.*\<bash\>\|^#!.*\<sh\>'
      return 'sh'
    endif
    if first =~# '^#!.*\<python'
      return 'python'
    endif
    if first =~# '^#!.*\<node\>\|^#!.*\<deno\>'
      return 'javascript'
    endif
    if first =~# '^#!.*\<ruby\>'
      return 'ruby'
    endif
    if first =~# '^#!.*\<perl\>'
      return 'perl'
    endif
  endif

  " Content heuristics
  if !empty(a:lines)
    let sample = join(a:lines[:min([20, len(a:lines)-1])], "\n")
    if sample =~# '^\s*\[.*\]\s*$'
      return 'dosini'
    endif
    if sample =~# '---' && sample =~# '^\s*\w\+:'
      return 'yaml'
    endif
  endif

  return ''
endfunction

" ---------------------------------------------------------------------------
" show({path}, {source})
" ---------------------------------------------------------------------------
function! neofinder#preview#show(path, source) abort
  " Don't preview for non-file sources or help
  if a:source ==# 'help' || a:source ==# 'palette' || a:source ==# 'services' || a:source ==# 'journal'
    return
  endif

  " Don't preview directories
  if isdirectory(a:path)
    return
  endif

  " For hosts source, the item might not be a file path
  if a:source ==# 'hosts' && !filereadable(a:path)
    return
  endif

  if !filereadable(a:path)
    return
  endif

  " Read first 100 lines for preview
  let lines = []
  try
    let lines = readfile(a:path, '', 100)
  catch
    return
  endtry

  " Check if file is binary
  let is_binary = 0
  for line in lines[:5]
    if line =~# '[^\x09\x0a\x0d\x20-\x7e\x80-\xff]'
      let is_binary = 1
      break
    endif
  endfor
  if is_binary
    let lines = ['  (binary file)']
  endif

  " Get or create preview window
  let preview_width = get(g:neofinder, 'preview_width', 60)

  if s:preview_winid > 0 && win_gotoid(s:preview_winid)
    " Reuse existing window
    setlocal modifiable
    silent! %delete _
  else
    " Create new preview split to the right
    let finder_winid = bufwinid(neofinder#core#state().bufnr)
    if finder_winid < 0
      return
    endif
    call win_gotoid(finder_winid)

    execute 'vertical rightbelow new'
    execute 'vertical resize ' . preview_width

    let s:preview_winid = win_getid()
    let s:preview_bufnr = bufnr('%')

    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
    setlocal nowrap nonumber norelativenumber nospell
  endif

  " Set content
  call setline(1, '  ' . a:path)
  call setline(2, repeat('-', preview_width - 2))
  for i in range(len(lines))
    call setline(i + 3, '  ' . lines[i])
  endfor

  " Detect and set filetype for syntax highlighting
  let ft = s:detect_filetype(a:path, lines)
  if ft !=# ''
    execute 'setlocal filetype=' . ft
    syntax enable
  endif

  setlocal autoindent smartindent
  setlocal nomodifiable

  " Apply Matrix theme to preview
  call neofinder#theme#set_preview_highlights()

  " Highlight the filename header
  call matchadd('NeoFinderPreviewTitle', '\%1l')

  " Return focus to finder window
  let finder_winid = bufwinid(neofinder#core#state().bufnr)
  if finder_winid > 0
    call win_gotoid(finder_winid)
  endif
endfunction

" ---------------------------------------------------------------------------
" resize({width}) -- resize preview window to given column width
" ---------------------------------------------------------------------------
function! neofinder#preview#resize(width) abort
  if s:preview_winid > 0
    let wid = win_id2win(s:preview_winid)
    if wid > 0
      execute wid . 'wincmd w'
      execute 'vertical resize ' . a:width
      " Return to finder
      let finder_winid = bufwinid(neofinder#core#state().bufnr)
      if finder_winid > 0
        call win_gotoid(finder_winid)
      endif
    endif
  endif
endfunction

" ---------------------------------------------------------------------------
" close()
" ---------------------------------------------------------------------------
function! neofinder#preview#close() abort
  if s:preview_winid > 0
    let wid = win_id2win(s:preview_winid)
    if wid > 0
      execute wid . 'wincmd c'
    endif
  endif
  let s:preview_winid = -1
  let s:preview_bufnr = -1
endfunction

