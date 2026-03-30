" neofinder#config  -- TOML config file for the plugin
"
" Config opens ~/.neofinder/config.toml in the editor.
" On save (:w), Python parses the TOML and applies it.

let s:config_path = expand('~/.neofinder/config.toml')
let s:parser_path = substitute(expand('<sfile>:p:h') . '/toml_parser.py', '\\', '/', 'g')

" ---------------------------------------------------------------------------
" open() -- opens config.toml in the editor
" ---------------------------------------------------------------------------
function! neofinder#config#open() abort
  let path = s:config_path
  if !filereadable(path)
    call s:create_default(path)
  endif
  execute 'edit ' . fnameescape(path)

  " Auto-reload on save
  augroup NeoFinderConfigReload
    autocmd! * <buffer>
    autocmd BufWritePost <buffer> call neofinder#config#load() | call neofinder#theme#apply()
          \ | echohl NeoFinderPrompt | echo '  Config reloaded' | echohl None
  augroup END
endfunction

" ---------------------------------------------------------------------------
" load() -- parse TOML via Python, apply to g:neofinder and editor
" ---------------------------------------------------------------------------
function! neofinder#config#load() abort
  if !filereadable(s:config_path)
    return
  endif

  " Parse TOML -> JSON string -> Vim dict
  if has('python3')
    try
      let json_str = s:parse_with_python()
      let data = json_decode(json_str)
    catch
      echohl ErrorMsg | echo '[NeoFinder] Config error: ' . v:exception | echohl None
      return
    endtry
  else
    " Fallback: simple line parser (no Python)
    let data = s:parse_toml_simple()
  endif

  call s:apply_config(data)
endfunction

" Parse TOML using Python
function! s:parse_with_python() abort
  let path = substitute(s:config_path, '\\', '/', 'g')
  execute 'py3file ' . fnameescape(s:parser_path)
  let result = py3eval('load_config("' . path . '")')
  return result
endfunction

" Fallback: basic TOML parser in pure Vimscript (no arrays, no nested)
function! s:parse_toml_simple() abort
  let lines = readfile(s:config_path)
  let data = {}
  let section = ''
  for line in lines
    let line = substitute(line, '#.*$', '', '')
    let line = substitute(line, '^\s\+\|\s\+$', '', 'g')
    if line ==# '' | continue | endif
    " Section
    let m = matchstr(line, '^\[\zs[^\]]\+\ze\]$')
    if m !=# ''
      let section = m
      if !has_key(data, section)
        let data[section] = {}
      endif
      continue
    endif
    " Key = Value
    let parts = matchlist(line, '^\(\w\+\)\s*=\s*\(.*\)$')
    if !empty(parts)
      let key = parts[1]
      let val = s:parse_val(parts[2])
      if section !=# ''
        let data[section][key] = val
      else
        let data[key] = val
      endif
    endif
  endfor
  return data
endfunction

function! s:parse_val(v) abort
  let v = substitute(a:v, '^\s\+\|\s\+$', '', 'g')
  if v ==# 'true'  | return 1 | endif
  if v ==# 'false' | return 0 | endif
  if v =~# '^-\?\d\+$' | return str2nr(v) | endif
  if v =~# '^".*"$' | return v[1:-2] | endif
  if v =~# "^'.*'$" | return v[1:-2] | endif
  if v =~# '^\[.*\]$'
    " Simple array parse
    let inner = v[1:-2]
    let items = []
    for item in split(inner, ',')
      call add(items, s:parse_val(item))
    endfor
    return items
  endif
  return v
endfunction

" ---------------------------------------------------------------------------
" Apply parsed config dict to g:neofinder and editor settings
" ---------------------------------------------------------------------------
function! s:apply_config(data) abort
  " Theme
  if has_key(a:data, 'theme')
    let t = a:data.theme
    if has_key(t, 'name')             | let g:neofinder.theme = t.name | endif
    if has_key(t, 'ascii_statusline') | let g:neofinder.ascii_statusline = t.ascii_statusline | endif
  endif

  " Finder
  if has_key(a:data, 'finder')
    let f = a:data.finder
    if has_key(f, 'height')        | let g:neofinder.height = f.height | endif
    if has_key(f, 'preview')       | let g:neofinder.preview = f.preview | endif
    if has_key(f, 'preview_width') | let g:neofinder.preview_width = f.preview_width | endif
    if has_key(f, 'max_files')     | let g:neofinder.max_files = f.max_files | endif
    if has_key(f, 'show_hidden')   | let g:neofinder.show_hidden = f.show_hidden | endif
    if has_key(f, 'sort_by')       | let g:neofinder.sort_by = f.sort_by | endif
  endif

  " Statusline
  if has_key(a:data, 'statusline')
    let sl = a:data.statusline
    if has_key(sl, 'enabled')
      let g:neofinder.statusline = sl.enabled
      if sl.enabled | call neofinder#statusline#enable() | else | call neofinder#statusline#disable() | endif
    endif
    if has_key(sl, 'show_clock')   | let g:neofinder.sl_clock = sl.show_clock | endif
    if has_key(sl, 'show_branch')  | let g:neofinder.sl_branch = sl.show_branch | endif
  endif

  " Editor
  if has_key(a:data, 'editor')
    let e = a:data.editor
    if has_key(e, 'line_numbers')     | execute 'set ' . (e.line_numbers ? '' : 'no') . 'number' | endif
    if has_key(e, 'relative_numbers') | execute 'set ' . (e.relative_numbers ? '' : 'no') . 'relativenumber' | endif
    if has_key(e, 'wrap')             | execute 'set ' . (e.wrap ? '' : 'no') . 'wrap' | endif
    if has_key(e, 'cursorline')       | execute 'set ' . (e.cursorline ? '' : 'no') . 'cursorline' | endif
    if has_key(e, 'cursorcolumn')     | execute 'set ' . (e.cursorcolumn ? '' : 'no') . 'cursorcolumn' | endif
    if has_key(e, 'tabstop')          | execute 'set tabstop=' . e.tabstop . ' shiftwidth=' . e.tabstop | endif
    if has_key(e, 'expandtab')        | execute 'set ' . (e.expandtab ? '' : 'no') . 'expandtab' | endif
    if has_key(e, 'encoding')
      try | execute 'set encoding=' . e.encoding | catch | endtry
    endif
    if has_key(e, 'autochdir')        | let g:neofinder.autochdir = e.autochdir | endif
    if has_key(e, 'scrolloff')        | execute 'set scrolloff=' . e.scrolloff | endif
    if has_key(e, 'sidescrolloff')    | execute 'set sidescrolloff=' . e.sidescrolloff | endif
    if has_key(e, 'mouse')            | execute 'set mouse=' . e.mouse | endif
    if has_key(e, 'clipboard')        | execute 'set clipboard=' . e.clipboard | endif
    if has_key(e, 'signcolumn')       | execute 'set signcolumn=' . e.signcolumn | endif
    if has_key(e, 'colorcolumn')      | execute 'set colorcolumn=' . e.colorcolumn | endif
    if has_key(e, 'textwidth')        | execute 'set textwidth=' . e.textwidth | endif
    if has_key(e, 'spell')            | execute 'set ' . (e.spell ? '' : 'no') . 'spell' | endif
    if has_key(e, 'spelllang')        | execute 'set spelllang=' . e.spelllang | endif
    if has_key(e, 'hidden')           | execute 'set ' . (e.hidden ? '' : 'no') . 'hidden' | endif
    if has_key(e, 'autowrite')        | execute 'set ' . (e.autowrite ? '' : 'no') . 'autowrite' | endif
    if has_key(e, 'backup')           | execute 'set ' . (e.backup ? '' : 'no') . 'backup' | endif
    if has_key(e, 'swapfile')         | execute 'set ' . (e.swapfile ? '' : 'no') . 'swapfile' | endif
    if has_key(e, 'undofile')         | execute 'set ' . (e.undofile ? '' : 'no') . 'undofile' | endif
    if has_key(e, 'undodir')          | execute 'set undodir=' . expand(e.undodir) | endif
    if has_key(e, 'updatetime')       | execute 'set updatetime=' . e.updatetime | endif
    if has_key(e, 'timeoutlen')       | execute 'set timeoutlen=' . e.timeoutlen | endif
    if has_key(e, 'lazyredraw')       | execute 'set ' . (e.lazyredraw ? '' : 'no') . 'lazyredraw' | endif
    if has_key(e, 'splitright')       | execute 'set ' . (e.splitright ? '' : 'no') . 'splitright' | endif
    if has_key(e, 'splitbelow')       | execute 'set ' . (e.splitbelow ? '' : 'no') . 'splitbelow' | endif
    if has_key(e, 'ignorecase')       | execute 'set ' . (e.ignorecase ? '' : 'no') . 'ignorecase' | endif
    if has_key(e, 'smartcase')        | execute 'set ' . (e.smartcase ? '' : 'no') . 'smartcase' | endif
    if has_key(e, 'incsearch')        | execute 'set ' . (e.incsearch ? '' : 'no') . 'incsearch' | endif
    if has_key(e, 'hlsearch')         | execute 'set ' . (e.hlsearch ? '' : 'no') . 'hlsearch' | endif
    if has_key(e, 'list')             | execute 'set ' . (e.list ? '' : 'no') . 'list' | endif
    if has_key(e, 'listchars')
      try | execute 'set listchars=' . e.listchars | catch | endtry
    endif
    if has_key(e, 'fillchars')
      try | execute 'set fillchars=' . e.fillchars | catch | endtry
    endif
  endif

  " Search
  if has_key(a:data, 'search')
    let s = a:data.search
    if has_key(s, 'ignorecase') | execute 'set ' . (s.ignorecase ? '' : 'no') . 'ignorecase' | endif
    if has_key(s, 'smartcase')  | execute 'set ' . (s.smartcase ? '' : 'no') . 'smartcase' | endif
    if has_key(s, 'incsearch')  | execute 'set ' . (s.incsearch ? '' : 'no') . 'incsearch' | endif
    if has_key(s, 'hlsearch')   | execute 'set ' . (s.hlsearch ? '' : 'no') . 'hlsearch' | endif
    if has_key(s, 'grepprg')    | execute 'set grepprg=' . escape(s.grepprg, ' ') | endif
  endif

  " Ignore
  if has_key(a:data, 'ignore')
    let g:neofinder.ignore = a:data.ignore
  endif

  " Paths
  if has_key(a:data, 'paths')
    let p = a:data.paths
    if has_key(p, 'tags')     | let g:neofinder.tag_file = expand(p.tags) | endif
    if has_key(p, 'undodir')  | execute 'set undodir=' . expand(p.undodir) | endif
    if has_key(p, 'backupdir') | execute 'set backupdir=' . expand(p.backupdir) | endif
  endif

  " Keybindings
  if has_key(a:data, 'keybindings')
    let kb = a:data.keybindings
    if has_key(kb, 'enabled')
      let g:neofinder.no_mappings = !kb.enabled
    endif

    " Custom bindings: [keybindings.map]
    if has_key(kb, 'map')
      for [key, cmd] in items(kb.map)
        " Expand special key notation
        let vimkey = s:expand_key(key)
        try
          execute 'nnoremap <silent> ' . vimkey . ' ' . cmd
        catch
        endtry
      endfor
    endif

    " Command bindings: [keybindings.commands]
    " Single letter = <Leader>nf + letter
    " Full key notation = used as-is
    if has_key(kb, 'commands')
      for [key, name] in items(kb.commands)
        if len(key) == 1
          let vimkey = '<Leader>nf' . key
        else
          let vimkey = s:expand_key(key)
        endif
        try
          execute 'nnoremap <silent> ' . vimkey . ' :NeoPythonExec ' . name . '<CR>'
        catch
        endtry
      endfor
    endif
  endif

  " Terminal
  if has_key(a:data, 'terminal')
    let t = a:data.terminal
    if has_key(t, 'shell') && t.shell !=# ''
      execute 'set shell=' . t.shell
    endif
  endif

  " Autocmds from config
  if has_key(a:data, 'on_save') && has_key(a:data.on_save, 'trim_whitespace') && a:data.on_save.trim_whitespace
    augroup NeoFinderTrimWhitespace
      autocmd!
      autocmd BufWritePre * %s/\s\+$//e
    augroup END
  endif
  if has_key(a:data, 'on_save') && has_key(a:data.on_save, 'final_newline') && a:data.on_save.final_newline
    augroup NeoFinderFinalNewline
      autocmd!
      autocmd BufWritePre * if getline('$') !=# '' | call append('$', '') | endif
    augroup END
  endif
endfunction

" Expand key notation: "Ctrl+s" -> "<C-s>", "Leader+w" -> "<Leader>w", etc.
function! s:expand_key(key) abort
  let k = a:key
  " Already Vim notation
  if k =~# '^<'
    return k
  endif
  " Ctrl+X -> <C-x>
  let k = substitute(k, 'Ctrl+\(.\)', '<C-\1>', 'g')
  " Alt+X -> <A-x>
  let k = substitute(k, 'Alt+\(.\)', '<A-\1>', 'g')
  " Shift+X -> <S-x>
  let k = substitute(k, 'Shift+\(.\)', '<S-\1>', 'g')
  " Leader+x -> <Leader>x
  let k = substitute(k, 'Leader+', '<Leader>', 'g')
  " F1-F12
  let k = substitute(k, 'F\(\d\+\)', '<F\1>', 'g')
  return k
endfunction

" ---------------------------------------------------------------------------
" Create default config.toml template
" ---------------------------------------------------------------------------
function! s:create_default(path) abort
  let dir = fnamemodify(a:path, ':h')
  if !isdirectory(dir)
    call mkdir(dir, 'p', 0700)
  endif
  call writefile([
        \ '# ══════════════════════════════════════════════════════════════════',
        \ '# NeoFinder Configuration',
        \ '# Save (:w) to apply changes instantly',
        \ '# ══════════════════════════════════════════════════════════════════',
        \ '',
        \ '',
        \ '# ── Theme ─────────────────────────────────────────────────────────',
        \ '# Options: "matrix", "dark", "cyberpunk", "default"',
        \ '[theme]',
        \ 'name = "matrix"',
        \ 'ascii_statusline = false       # true for terminals without powerline fonts',
        \ '',
        \ '',
        \ '# ── Finder Panel ──────────────────────────────────────────────────',
        \ '[finder]',
        \ 'height = 15                    # panel height in lines (10-30)',
        \ 'preview = true                 # file preview pane on the right',
        \ 'preview_width = 60             # preview pane width in columns',
        \ 'max_files = 50000              # max files to scan (10000-100000)',
        \ 'show_hidden = true             # show dotfiles in browser',
        \ 'sort_by = "name"               # "name", "modified", "size"',
        \ '',
        \ '',
        \ '# ── Statusline ────────────────────────────────────────────────────',
        \ '[statusline]',
        \ 'enabled = true',
        \ 'show_clock = true              # clock in the right side',
        \ 'show_branch = true             # git branch name',
        \ '',
        \ '',
        \ '# ── Editor ────────────────────────────────────────────────────────',
        \ '[editor]',
        \ '# Display',
        \ 'line_numbers = false',
        \ 'relative_numbers = false',
        \ 'wrap = true',
        \ 'cursorline = false',
        \ 'cursorcolumn = false',
        \ 'colorcolumn = ""               # "80" or "80,120" for guides',
        \ 'signcolumn = "auto"            # "auto", "yes", "no"',
        \ 'scrolloff = 5                  # lines to keep above/below cursor',
        \ 'sidescrolloff = 8              # columns to keep left/right',
        \ '',
        \ '# Indentation',
        \ 'tabstop = 4                    # 2, 4, or 8',
        \ 'expandtab = true               # true = spaces, false = tabs',
        \ '',
        \ '# Files & buffers',
        \ 'encoding = "utf-8"             # utf-8, latin1, cp1252',
        \ 'autochdir = true                # cwd follows the active file',
        \ 'hidden = true                  # allow hidden buffers with unsaved changes',
        \ 'autowrite = false              # auto-save before :make, :next, etc.',
        \ 'swapfile = false               # disable .swp files',
        \ 'backup = false                 # disable ~ backup files',
        \ 'undofile = true                # persistent undo across sessions',
        \ '',
        \ '# Clipboard',
        \ 'mouse = "a"                    # "a" = all modes, "" = disabled',
        \ 'clipboard = "unnamedplus"      # "unnamedplus" = system clipboard',
        \ '',
        \ '# Performance',
        \ 'updatetime = 300               # ms before CursorHold fires (300-1000)',
        \ 'timeoutlen = 500               # ms to wait for key sequence',
        \ 'lazyredraw = false             # true = faster macros, less flicker',
        \ '',
        \ '# Splits',
        \ 'splitright = true              # vsplit opens to the right',
        \ 'splitbelow = true              # split opens below',
        \ '',
        \ '# Whitespace characters (when :set list)',
        \ 'list = false',
        \ 'listchars = "tab:> ,trail:-,nbsp:+"',
        \ '',
        \ '# Spell check',
        \ 'spell = false',
        \ 'spelllang = "en"               # "en", "es", "en,es"',
        \ '',
        \ '',
        \ '# ── Search ────────────────────────────────────────────────────────',
        \ '[search]',
        \ 'ignorecase = true              # case insensitive by default',
        \ 'smartcase = true               # case sensitive if uppercase in query',
        \ 'incsearch = true               # search as you type',
        \ 'hlsearch = true                # highlight all matches',
        \ 'grepprg = "grep -rn"           # external grep: "rg --vimgrep" if available',
        \ '',
        \ '',
        \ '# ── Terminal ──────────────────────────────────────────────────────',
        \ '[terminal]',
        \ 'shell = ""                     # empty = system default, or "/bin/bash", "pwsh"',
        \ '',
        \ '',
        \ '# ── On Save ───────────────────────────────────────────────────────',
        \ '# Actions to run automatically when saving a file',
        \ '[on_save]',
        \ 'trim_whitespace = true         # remove trailing spaces',
        \ 'final_newline = true           # ensure file ends with newline',
        \ '',
        \ '',
        \ '# ── Ignore Patterns ───────────────────────────────────────────────',
        \ '# Directories and files to skip in the file finder',
        \ 'ignore = [".git", "node_modules", "__pycache__", ".cache", "/proc", "/sys", "/dev", "/run", "/snap", "/lost+found"]',
        \ '',
        \ '',
        \ '# ── Paths ─────────────────────────────────────────────────────────',
        \ '[paths]',
        \ 'tags = "~/.neofinder/tags"',
        \ 'commands = "~/.neofinder/python"',
        \ 'undodir = "~/.neofinder/undo"  # persistent undo directory',
        \ 'backupdir = "~/.neofinder/backup"',
        \ '',
        \ '',
        \ '# ── Keybindings ───────────────────────────────────────────────────',
        \ '[keybindings]',
        \ 'enabled = true                 # false to disable all <Leader>f mappings',
        \ '',
        \ '# Custom key mappings (normal mode)',
        \ '# Format: key = "vim command"',
        \ '# Key notation: Ctrl+s, Alt+x, Shift+t, Leader+w, F5, or Vim style <C-s>',
        \ '[keybindings.map]',
        \ '# Ctrl+s = ":w<CR>"                   # save file',
        \ '# Ctrl+q = ":q<CR>"                   # quit',
        \ '# Leader+w = ":w<CR>"                 # save with leader',
        \ '# F5 = ":!python3 %<CR>"              # run current python file',
        \ '# F9 = ":!gcc % -o %:r && ./%:r<CR>"  # compile & run C',
        \ '',
        \ '# Bind NeoFinder commands to keys',
        \ '# Single letter = <Leader>nf + letter (namespace)',
        \ '# Full key = used as-is (F2, Ctrl+x, etc.)',
        \ '[keybindings.commands]',
        \ '# a = "NetInfo"                       # <Leader>nfa  network info',
        \ '# b = "NetScan"                       # <Leader>nfb  port scan',
        \ '# c = "NetConns"                      # <Leader>nfc  connections',
        \ '# d = "GitLog"                        # <Leader>nfd  git log',
        \ '# e = "GrepHere"                      # <Leader>nfe  grep',
        \ '# f = "RunHere"                       # <Leader>nff  run shell command',
        \ '# F2 = "NetInfo"                      # F2 key directly',
        \ ], a:path)
endfunction
