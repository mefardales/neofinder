" neofinder#config  -- JSON config file for the plugin
"
" Config opens ~/.neofinder/config.json in the editor.
" On save (:w), it auto-reloads.

let s:config_path = expand('~/.neofinder/config.json')

" ---------------------------------------------------------------------------
" open() -- the only entry point. Opens the JSON in the editor.
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
" load() -- read config.json, apply to g:neofinder and editor
" ---------------------------------------------------------------------------
function! neofinder#config#load() abort
  if !filereadable(s:config_path)
    return
  endif
  try
    let raw = join(readfile(s:config_path), '')
    let data = json_decode(raw)
  catch
    echohl ErrorMsg | echo '[NeoFinder] Bad config.json: ' . v:exception | echohl None
    return
  endtry

  " Theme
  if has_key(data, 'theme')
    let t = data.theme
    if has_key(t, 'name')             | let g:neofinder.theme = t.name | endif
    if has_key(t, 'ascii_statusline') | let g:neofinder.ascii_statusline = t.ascii_statusline | endif
  endif

  " Finder
  if has_key(data, 'finder')
    let f = data.finder
    if has_key(f, 'height')        | let g:neofinder.height = f.height | endif
    if has_key(f, 'preview')       | let g:neofinder.preview = f.preview | endif
    if has_key(f, 'preview_width') | let g:neofinder.preview_width = f.preview_width | endif
    if has_key(f, 'max_files')     | let g:neofinder.max_files = f.max_files | endif
  endif

  " Statusline
  if has_key(data, 'statusline') && has_key(data.statusline, 'enabled')
    let g:neofinder.statusline = data.statusline.enabled
    if data.statusline.enabled
      call neofinder#statusline#enable()
    else
      call neofinder#statusline#disable()
    endif
  endif

  " Editor
  if has_key(data, 'editor')
    let e = data.editor
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
  if has_key(data, 'ignore')
    let g:neofinder.ignore = data.ignore
  endif

  " Paths
  if has_key(data, 'paths')
    if has_key(data.paths, 'tags')     | let g:neofinder.tag_file = expand(data.paths.tags) | endif
  endif

  " Keybindings
  if has_key(data, 'keybindings') && has_key(data.keybindings, 'enabled')
    let g:neofinder.no_mappings = !data.keybindings.enabled
  endif
endfunction

" ---------------------------------------------------------------------------
" create_default() -- write the full template config.json
" ---------------------------------------------------------------------------
function! s:create_default(path) abort
  let dir = fnamemodify(a:path, ':h')
  if !isdirectory(dir)
    call mkdir(dir, 'p', 0700)
  endif
  call writefile([
        \ '{',
        \ '',
        \ '  // ── Theme ──────────────────────────────────────────────',
        \ '  // options: "matrix", "dark", "cyberpunk", "default"',
        \ '  "theme": {',
        \ '    "name": "matrix",',
        \ '    "ascii_statusline": false',
        \ '  },',
        \ '',
        \ '  // ── Finder Panel ────────────────────────────────────────',
        \ '  "finder": {',
        \ '    "height": 15,              // panel height in lines (10-30)',
        \ '    "preview": true,           // show file preview pane',
        \ '    "preview_width": 60,       // preview pane width in columns',
        \ '    "max_files": 50000         // max files to scan',
        \ '  },',
        \ '',
        \ '  // ── Statusline ──────────────────────────────────────────',
        \ '  "statusline": {',
        \ '    "enabled": true',
        \ '  },',
        \ '',
        \ '  // ── Editor Defaults ─────────────────────────────────────',
        \ '  "editor": {',
        \ '    "line_numbers": false,',
        \ '    "relative_numbers": false,',
        \ '    "wrap": true,',
        \ '    "cursorline": false,',
        \ '    "tabstop": 4,              // 2, 4, or 8',
        \ '    "expandtab": true,         // true = spaces, false = tabs',
        \ '    "encoding": "utf-8"        // utf-8, latin1, cp1252',
        \ '  },',
        \ '',
        \ '  // ── Ignore Patterns ─────────────────────────────────────',
        \ '  // Directories and files to skip in file finder',
        \ '  "ignore": [',
        \ '    ".git",',
        \ '    "node_modules",',
        \ '    "__pycache__",',
        \ '    ".cache",',
        \ '    "/proc",',
        \ '    "/sys",',
        \ '    "/dev",',
        \ '    "/run",',
        \ '    "/snap",',
        \ '    "/lost+found"',
        \ '  ],',
        \ '',
        \ '  // ── Paths ───────────────────────────────────────────────',
        \ '  "paths": {',
        \ '    "tags": "~/.neofinder/tags",',
        \ '    "commands": "~/.neofinder/python"',
        \ '  },',
        \ '',
        \ '  // ── Keybindings ─────────────────────────────────────────',
        \ '  "keybindings": {',
        \ '    "enabled": true,           // false to disable all default mappings',
        \ '    "leader_prefix": "<Leader>f"',
        \ '  }',
        \ '',
        \ '}',
        \ ], a:path)
endfunction
