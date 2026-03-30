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
  endif

  " Statusline
  if has_key(a:data, 'statusline') && has_key(a:data.statusline, 'enabled')
    let g:neofinder.statusline = a:data.statusline.enabled
    if a:data.statusline.enabled
      call neofinder#statusline#enable()
    else
      call neofinder#statusline#disable()
    endif
  endif

  " Editor
  if has_key(a:data, 'editor')
    let e = a:data.editor
    if has_key(e, 'line_numbers')     | execute 'set ' . (e.line_numbers ? '' : 'no') . 'number' | endif
    if has_key(e, 'relative_numbers') | execute 'set ' . (e.relative_numbers ? '' : 'no') . 'relativenumber' | endif
    if has_key(e, 'wrap')             | execute 'set ' . (e.wrap ? '' : 'no') . 'wrap' | endif
    if has_key(e, 'cursorline')       | execute 'set ' . (e.cursorline ? '' : 'no') . 'cursorline' | endif
    if has_key(e, 'tabstop')          | execute 'set tabstop=' . e.tabstop . ' shiftwidth=' . e.tabstop | endif
    if has_key(e, 'expandtab')        | execute 'set ' . (e.expandtab ? '' : 'no') . 'expandtab' | endif
    if has_key(e, 'encoding')
      try | execute 'set encoding=' . e.encoding | catch | endtry
    endif
  endif

  " Ignore
  if has_key(a:data, 'ignore')
    let g:neofinder.ignore = a:data.ignore
  endif

  " Paths
  if has_key(a:data, 'paths')
    if has_key(a:data.paths, 'tags') | let g:neofinder.tag_file = expand(a:data.paths.tags) | endif
  endif

  " Keybindings
  if has_key(a:data, 'keybindings') && has_key(a:data.keybindings, 'enabled')
    let g:neofinder.no_mappings = !a:data.keybindings.enabled
  endif
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
        \ '# ══════════════════════════════════════════════════════════',
        \ '# NeoFinder Configuration',
        \ '# Save (:w) to apply changes instantly',
        \ '# ══════════════════════════════════════════════════════════',
        \ '',
        \ '# ── Theme ─────────────────────────────────────────────────',
        \ '# Options: "matrix", "dark", "cyberpunk", "default"',
        \ '[theme]',
        \ 'name = "matrix"',
        \ 'ascii_statusline = false',
        \ '',
        \ '# ── Finder Panel ──────────────────────────────────────────',
        \ '[finder]',
        \ 'height = 15            # Panel height: 10, 15, 20, 25, 30',
        \ 'preview = true         # Show file preview pane',
        \ 'preview_width = 60     # Preview width in columns',
        \ 'max_files = 50000      # Max files to scan: 10000, 25000, 50000, 100000',
        \ '',
        \ '# ── Statusline ────────────────────────────────────────────',
        \ '[statusline]',
        \ 'enabled = true',
        \ '',
        \ '# ── Editor Defaults ───────────────────────────────────────',
        \ '[editor]',
        \ 'line_numbers = false',
        \ 'relative_numbers = false',
        \ 'wrap = true',
        \ 'cursorline = false',
        \ 'tabstop = 4            # 2, 4, or 8',
        \ 'expandtab = true       # true = spaces, false = tabs',
        \ 'encoding = "utf-8"     # utf-8, latin1, cp1252',
        \ '',
        \ '# ── Ignore Patterns ───────────────────────────────────────',
        \ '# Directories/files to skip in file finder',
        \ 'ignore = [".git", "node_modules", "__pycache__", ".cache", "/proc", "/sys", "/dev", "/run", "/snap", "/lost+found"]',
        \ '',
        \ '# ── Paths ─────────────────────────────────────────────────',
        \ '[paths]',
        \ 'tags = "~/.neofinder/tags"',
        \ 'commands = "~/.neofinder/python"',
        \ '',
        \ '# ── Keybindings ───────────────────────────────────────────',
        \ '[keybindings]',
        \ 'enabled = true         # false to disable all <Leader>f mappings',
        \ ], a:path)
endfunction
