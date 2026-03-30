" neofinder#config  -- Settings panel for the plugin and the editor

let s:config_bufnr = -1
let s:config_winid = -1
let s:config_cursor = 0
let s:menu_items = []

function! neofinder#config#open() abort
  call s:build_menu()
  call s:create_panel()
  call s:render_panel()
  call s:panel_loop()
endfunction

" ===========================================================================
" Menu
" ===========================================================================
function! s:build_menu() abort
  let s:config_cursor = 0
  let s:menu_items = []

  " -- THEME --
  call s:header('THEME')
  let current = get(g:neofinder, 'theme', 'matrix')
  for t in neofinder#theme#list()
    let m = (t ==# current) ? '  *' : ''
    call add(s:menu_items, {
          \ 'label': printf('  %s%s', t, m),
          \ 'type': 'action', 'action': 'switch_theme', 'value': t})
  endfor

  " -- EDITOR --
  call s:header('EDITOR')
  let ed_num = s:get_editor_option('number')
  let ed_rnum = s:get_editor_option('relativenumber')
  call s:item('Line numbers',
        \ ed_num ? (ed_rnum ? 'relative' : 'ON') : 'OFF',
        \ 'cycle_numbers')
  call s:item('Wrap',
        \ s:get_editor_option('wrap') ? 'ON' : 'OFF',
        \ 'toggle_wrap')
  call s:item('Cursor line',
        \ s:get_editor_option('cursorline') ? 'ON' : 'OFF',
        \ 'toggle_cursorline')
  call s:item('Paste mode',
        \ &paste ? 'ON' : 'OFF',
        \ 'toggle_paste')
  call s:item('Tab size',
        \ &tabstop . ' spaces',
        \ 'cycle_tabsize')
  call s:item('Expand tabs',
        \ &expandtab ? 'spaces' : 'tabs',
        \ 'toggle_expandtab')
  call s:item('Encoding',
        \ &encoding,
        \ 'cycle_encoding')

  " -- PLUGIN --
  call s:header('PLUGIN')
  call s:item('Statusline',
        \ &statusline =~# 'neofinder#statusline' ? 'ON' : 'OFF',
        \ 'toggle_statusline')
  call s:item('Preview pane',
        \ get(g:neofinder, 'preview', 1) ? 'ON' : 'OFF',
        \ 'toggle_preview')
  call s:item('Finder height',
        \ get(g:neofinder, 'height', 15),
        \ 'cycle_height')
  call s:item('Max files',
        \ get(g:neofinder, 'max_files', 50000),
        \ 'cycle_max_files')

  " -- PATHS --
  call s:header('PATHS')
  call s:item('Commands dir',
        \ neofinder#python#user_dir(),
        \ 'open_commands_dir')
  call s:item('Edit config.json',
        \ s:config_file_path(),
        \ 'open_plugin_config')
  call s:item('Save config',
        \ 'write current state to json',
        \ 'save_config')
  call s:item('Reload config',
        \ 'apply config.json now',
        \ 'reload_config')

  " -- COMMANDS --
  call s:header('COMMANDS')
  let pycount = len(neofinder#python#list())
  call s:item('Loaded',
        \ pycount . ' commands',
        \ 'list_python')
  call s:item('Reload',
        \ '~/.neofinder/python/',
        \ 'reload_python')

  " -- INFO --
  call s:header('SYSTEM')
  call s:info('Backend', neofinder#backend())
  call s:info('Vim', v:version . (has('nvim') ? ' (nvim)' : ''))
  call s:info('Python3', has('python3') ? 'yes' : 'no')
  call s:info('OS', s:detect_os())
endfunction

" ===========================================================================
" Menu helpers
" ===========================================================================
function! s:header(t) abort
  call add(s:menu_items, {'label': '', 'type': 'separator'})
  call add(s:menu_items, {'label': '--- ' . a:t . ' ---', 'type': 'header'})
endfunction

function! s:item(label, val, action) abort
  call add(s:menu_items, {
        \ 'label': printf('  %-22s %s', a:label, a:val),
        \ 'type': 'action', 'action': a:action})
endfunction

function! s:info(label, val) abort
  call add(s:menu_items, {
        \ 'label': printf('  %-22s %s', a:label, a:val),
        \ 'type': 'info'})
endfunction

function! s:short_list(paths) abort
  if empty(a:paths) | return '(none)' | endif
  let home = expand('~')
  let out = []
  for p in a:paths[:1]
    call add(out, substitute(p, '^' . home, '~', ''))
  endfor
  let r = join(out, ', ')
  if len(a:paths) > 2
    let r .= ' (+' . (len(a:paths) - 2) . ')'
  endif
  return r
endfunction

function! s:detect_os() abort
  if has('mac') | return 'macOS' | endif
  if has('win32') | return 'Windows' | endif
  if filereadable('/etc/os-release')
    for line in readfile('/etc/os-release', '', 5)
      if line =~# '^PRETTY_NAME='
        return matchstr(line, '"\zs[^"]*')
      endif
    endfor
  endif
  return 'Linux'
endfunction

" ===========================================================================
" Panel buffer
" ===========================================================================
function! s:create_panel() abort
  call s:close_panel()
  botright new
  let s:config_bufnr = bufnr('%')
  let s:config_winid = win_getid()
  execute 'resize ' . min([len(s:menu_items) + 4, 30])
  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
  setlocal nowrap nonumber norelativenumber nospell
  setlocal nocursorline nocursorcolumn filetype=neofinder-config
  call neofinder#theme#set_buffer_highlights()
endfunction

function! s:close_panel() abort
  if s:config_bufnr > 0 && bufexists(s:config_bufnr)
    execute 'bwipeout! ' . s:config_bufnr
  endif
  let s:config_bufnr = -1
  let s:config_winid = -1
endfunction

" ===========================================================================
" Render
" ===========================================================================
function! s:render_panel() abort
  if s:config_bufnr < 0 || !bufexists(s:config_bufnr) | return | endif
  call win_gotoid(bufwinid(s:config_bufnr))
  setlocal modifiable
  silent! %delete _

  call setline(1, '  Settings          [q] close  [Enter] toggle  [j/k] move')
  call setline(2, repeat('-', 62))

  let lnum = 3
  for i in range(len(s:menu_items))
    let item = s:menu_items[i]
    let ptr = item.type ==# 'action' ? (i == s:config_cursor ? '> ' : '  ') : ''
    call setline(lnum, ptr . item.label)
    let lnum += 1
  endfor

  setlocal nomodifiable
  call clearmatches()
  call matchadd('NeoFinderPrompt', '\%1l')
  call matchadd('NeoFinderBorder', '\%2l')
  call matchadd('NeoFinderStatus', '^--- .\+ ---$')
  call matchadd('NeoFinderSelected', '  \*$')
  let cl = s:config_cursor + 3
  if cl >= 3
    call matchadd('NeoFinderCursor', '\%' . cl . 'l')
  endif
endfunction

" ===========================================================================
" Navigation
" ===========================================================================
function! s:move_cursor(dir) abort
  let pos = s:config_cursor + a:dir
  while pos >= 0 && pos < len(s:menu_items)
    if s:menu_items[pos].type ==# 'action'
      let s:config_cursor = pos
      return
    endif
    let pos += a:dir
  endwhile
endfunction

function! s:snap_cursor() abort
  if s:config_cursor < len(s:menu_items) && s:menu_items[s:config_cursor].type ==# 'action'
    return
  endif
  call s:move_cursor(1)
endfunction

" ===========================================================================
" Input loop
" ===========================================================================
function! s:panel_loop() abort
  call s:snap_cursor()
  call s:render_panel()
  while 1
    redraw
    echo ''
    let c = getchar()
    let ch = type(c) == type(0) ? nr2char(c) : c

    if c == 27 || c == 3 || ch ==# 'q'
      call s:close_panel()
      return
    endif
    if c == 13
      let save = s:config_cursor
      call s:execute_action()
      call s:build_menu()
      let s:config_cursor = min([save, len(s:menu_items) - 1])
      call s:snap_cursor()
      call s:render_panel()
      continue
    endif
    if c == 10 || c == 14 || ch ==# "\<Down>" || ch ==# 'j'
      call s:move_cursor(1)
      call s:render_panel()
      continue
    endif
    if c == 11 || c == 16 || ch ==# "\<Up>" || ch ==# 'k'
      call s:move_cursor(-1)
      call s:render_panel()
      continue
    endif
    if ch ==# "\<S-Up>"
      resize +2
      call s:render_panel()
      continue
    endif
    if ch ==# "\<S-Down>"
      resize -2
      call s:render_panel()
      continue
    endif
  endwhile
endfunction

" ===========================================================================
" Actions
" ===========================================================================
function! s:execute_action() abort
  let item = s:menu_items[s:config_cursor]
  if item.type !=# 'action' | return | endif
  let a = item.action

  " -- Theme --
  if a ==# 'switch_theme'
    let g:neofinder.theme = item.value
    call neofinder#theme#apply()
    call neofinder#theme#set_buffer_highlights()

  " -- Editor --
  elseif a ==# 'cycle_numbers'
    let ed_num = s:get_editor_option('number')
    let ed_rnum = s:get_editor_option('relativenumber')
    if !ed_num
      call s:apply_to_all('number', 1)
      call s:apply_to_all('relativenumber', 0)
    elseif !ed_rnum
      call s:apply_to_all('number', 1)
      call s:apply_to_all('relativenumber', 1)
    else
      call s:apply_to_all('number', 0)
      call s:apply_to_all('relativenumber', 0)
    endif
  elseif a ==# 'toggle_wrap'
    let v = !s:get_editor_option('wrap')
    call s:apply_to_all('wrap', v)
  elseif a ==# 'toggle_cursorline'
    let v = !s:get_editor_option('cursorline')
    call s:apply_to_all('cursorline', v)
  elseif a ==# 'toggle_paste'
    set paste!
  elseif a ==# 'cycle_tabsize'
    let sizes = [2, 4, 8]
    let cur = &tabstop
    let idx = index(sizes, cur)
    let next = sizes[(idx + 1) % len(sizes)]
    execute 'set tabstop=' . next . ' shiftwidth=' . next
  elseif a ==# 'toggle_expandtab'
    set expandtab!
  elseif a ==# 'cycle_encoding'
    let encs = ['utf-8', 'latin1', 'cp1252']
    let idx = index(encs, &encoding)
    let next = encs[(idx + 1) % len(encs)]
    execute 'set encoding=' . next

  " -- Plugin --
  elseif a ==# 'toggle_statusline'
    call neofinder#statusline#toggle()
  elseif a ==# 'toggle_preview'
    let g:neofinder.preview = !get(g:neofinder, 'preview', 1)
  elseif a ==# 'cycle_height'
    let heights = [10, 15, 20, 25]
    let cur = get(g:neofinder, 'height', 15)
    let idx = index(heights, cur)
    let g:neofinder.height = heights[(idx + 1) % len(heights)]
  elseif a ==# 'cycle_max_files'
    let vals = [10000, 25000, 50000, 100000]
    let cur = get(g:neofinder, 'max_files', 50000)
    let idx = index(vals, cur)
    let g:neofinder.max_files = vals[(idx + 1) % len(vals)]

  " -- Paths --
  elseif a ==# 'open_commands_dir'
    call s:close_panel()
    let dir = neofinder#python#user_dir()
    if !isdirectory(dir)
      call mkdir(dir, 'p', 0700)
    endif
    call neofinder#browse(dir)
  elseif a ==# 'open_plugin_config'
    call s:close_panel()
    let path = s:config_file_path()
    if !filereadable(path)
      call s:create_config_file(path)
    endif
    execute 'edit ' . fnameescape(path)
  elseif a ==# 'save_config'
    call neofinder#config#save()
    sleep 500m
  elseif a ==# 'reload_config'
    call neofinder#config#load()
    call neofinder#theme#apply()
    call neofinder#theme#set_buffer_highlights()
    echohl NeoFinderPrompt | echo '  Config reloaded' | echohl None
    sleep 500m

  " -- Commands --
  elseif a ==# 'list_python'
    call s:close_panel()
    call neofinder#python#show_list()
    call input('[Enter]')
    call s:reopen()
  elseif a ==# 'reload_python'
    call neofinder#python#autoload()
  endif
endfunction

" ===========================================================================
" Helpers
" ===========================================================================
function! s:config_file_path() abort
  return expand('~/.neofinder/config.json')
endfunction

function! s:create_config_file(path) abort
  let dir = fnamemodify(a:path, ':h')
  if !isdirectory(dir)
    call mkdir(dir, 'p', 0700)
  endif
  let lines = [
        \ '{',
        \ '  "_comment": "NeoFinder configuration - edit and reload with :Neo > Config > Reload",',
        \ '',
        \ '  "theme": {',
        \ '    "name": "matrix",',
        \ '    "_options": ["matrix", "dark", "cyberpunk", "default"],',
        \ '    "ascii_statusline": false',
        \ '  },',
        \ '',
        \ '  "finder": {',
        \ '    "height": 15,',
        \ '    "_height_options": [10, 15, 20, 25, 30],',
        \ '    "preview": true,',
        \ '    "preview_width": 60,',
        \ '    "max_files": 50000,',
        \ '    "_max_files_options": [10000, 25000, 50000, 100000]',
        \ '  },',
        \ '',
        \ '  "statusline": {',
        \ '    "enabled": true',
        \ '  },',
        \ '',
        \ '  "editor": {',
        \ '    "line_numbers": false,',
        \ '    "relative_numbers": false,',
        \ '    "wrap": true,',
        \ '    "cursorline": false,',
        \ '    "tabstop": 4,',
        \ '    "_tabstop_options": [2, 4, 8],',
        \ '    "expandtab": true,',
        \ '    "encoding": "utf-8",',
        \ '    "_encoding_options": ["utf-8", "latin1", "cp1252"]',
        \ '  },',
        \ '',
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
        \ '  "paths": {',
        \ '    "tags": "~/.neofinder/tags",',
        \ '    "commands": "~/.neofinder/python"',
        \ '  },',
        \ '',
        \ '  "keybindings": {',
        \ '    "_comment": "Set to false to disable default mappings",',
        \ '    "enabled": true,',
        \ '    "leader_prefix": "<Leader>f"',
        \ '  }',
        \ '}',
        \ ]
  call writefile(lines, path)
endfunction

" Load config.json and apply to g:neofinder
function! neofinder#config#load() abort
  let path = s:config_file_path()
  if !filereadable(path)
    return
  endif
  try
    let raw = join(readfile(path), '')
    let data = json_decode(raw)
  catch
    echohl ErrorMsg | echo '[NeoFinder] Bad config.json: ' . v:exception | echohl None
    return
  endtry

  " Theme
  if has_key(data, 'theme')
    let t = data.theme
    if has_key(t, 'name')           | let g:neofinder.theme = t.name | endif
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
  if has_key(data, 'statusline')
    if has_key(data.statusline, 'enabled') | let g:neofinder.statusline = data.statusline.enabled | endif
  endif

  " Editor settings
  if has_key(data, 'editor')
    let e = data.editor
    if has_key(e, 'line_numbers')     | execute 'set ' . (e.line_numbers ? '' : 'no') . 'number' | endif
    if has_key(e, 'relative_numbers') | execute 'set ' . (e.relative_numbers ? '' : 'no') . 'relativenumber' | endif
    if has_key(e, 'wrap')             | execute 'set ' . (e.wrap ? '' : 'no') . 'wrap' | endif
    if has_key(e, 'cursorline')       | execute 'set ' . (e.cursorline ? '' : 'no') . 'cursorline' | endif
    if has_key(e, 'tabstop')          | execute 'set tabstop=' . e.tabstop . ' shiftwidth=' . e.tabstop | endif
    if has_key(e, 'expandtab')        | execute 'set ' . (e.expandtab ? '' : 'no') . 'expandtab' | endif
    if has_key(e, 'encoding')         | try | execute 'set encoding=' . e.encoding | catch | endtry | endif
  endif

  " Ignore
  if has_key(data, 'ignore')
    let g:neofinder.ignore = data.ignore
  endif

  " Paths
  if has_key(data, 'paths')
    if has_key(data.paths, 'tags') | let g:neofinder.tag_file = expand(data.paths.tags) | endif
  endif

  " Keybindings
  if has_key(data, 'keybindings')
    if has_key(data.keybindings, 'enabled') && !data.keybindings.enabled
      let g:neofinder.no_mappings = 1
    endif
  endif
endfunction

" Save current state back to config.json
function! neofinder#config#save() abort
  let path = s:config_file_path()
  let dir = fnamemodify(path, ':h')
  if !isdirectory(dir)
    call mkdir(dir, 'p', 0700)
  endif

  let data = {
        \ 'theme': {
        \   'name': get(g:neofinder, 'theme', 'matrix'),
        \   '_options': ['matrix', 'dark', 'cyberpunk', 'default'],
        \   'ascii_statusline': get(g:neofinder, 'ascii_statusline', 0),
        \ },
        \ 'finder': {
        \   'height': get(g:neofinder, 'height', 15),
        \   '_height_options': [10, 15, 20, 25, 30],
        \   'preview': get(g:neofinder, 'preview', 1),
        \   'preview_width': get(g:neofinder, 'preview_width', 60),
        \   'max_files': get(g:neofinder, 'max_files', 50000),
        \   '_max_files_options': [10000, 25000, 50000, 100000],
        \ },
        \ 'statusline': {
        \   'enabled': &statusline =~# 'neofinder#statusline' ? 1 : 0,
        \ },
        \ 'editor': {
        \   'line_numbers': &number ? 1 : 0,
        \   'relative_numbers': &relativenumber ? 1 : 0,
        \   'wrap': &wrap ? 1 : 0,
        \   'cursorline': &cursorline ? 1 : 0,
        \   'tabstop': &tabstop,
        \   '_tabstop_options': [2, 4, 8],
        \   'expandtab': &expandtab ? 1 : 0,
        \   'encoding': &encoding,
        \   '_encoding_options': ['utf-8', 'latin1', 'cp1252'],
        \ },
        \ 'ignore': get(g:neofinder, 'ignore', []),
        \ 'paths': {
        \   'tags': get(g:neofinder, 'tag_file', '~/.neofinder/tags'),
        \   'commands': neofinder#python#user_dir(),
        \ },
        \ 'keybindings': {
        \   'enabled': !get(g:neofinder, 'no_mappings', 0) ? 1 : 0,
        \   'leader_prefix': '<Leader>f',
        \ },
        \ }

  let json = json_encode(data)
  " Pretty print (basic: add newlines after { and , )
  let json = substitute(json, '{', "{\n  ", 'g')
  let json = substitute(json, '}', "\n}", 'g')
  let json = substitute(json, ',', ",\n  ", 'g')
  call writefile(split(json, "\n"), path)

  echohl NeoFinderPrompt | echo '  Config saved: ' . path | echohl None
endfunction

function! s:get_editor_option(opt) abort
  for win in range(1, winnr('$'))
    let bnr = winbufnr(win)
    if bnr != s:config_bufnr && getbufvar(bnr, '&buftype') ==# ''
      return getwinvar(win, '&' . a:opt)
    endif
  endfor
  return eval('&' . a:opt)
endfunction

function! s:apply_to_all(option, value) abort
  let save_win = win_getid()
  execute 'set ' . a:option . (a:value ? '' : '!')
  for win in range(1, winnr('$'))
    execute win . 'wincmd w'
    execute 'setlocal ' . (a:value ? '' : 'no') . a:option
  endfor
  call win_gotoid(save_win)
endfunction

function! s:reopen() abort
  call s:build_menu()
  call s:create_panel()
  call s:snap_cursor()
  call s:render_panel()
endfunction
