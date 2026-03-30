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
  call s:item('Config paths',
        \ s:short_list(get(g:neofinder, 'config_paths', [])),
        \ 'edit_config_paths')
  call s:item('Log paths',
        \ s:short_list(get(g:neofinder, 'log_paths', [])),
        \ 'edit_log_paths')
  call s:item('Script paths',
        \ s:short_list(get(g:neofinder, 'script_paths', [])),
        \ 'edit_script_paths')
  call s:item('Ignore patterns',
        \ string(len(get(g:neofinder, 'ignore', []))) . ' rules',
        \ 'edit_ignore')
  call s:item('SSH config',
        \ get(g:neofinder, 'ssh_config', '~/.ssh/config'),
        \ 'set_ssh_config')

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
  elseif a ==# 'edit_config_paths'
    call s:edit_paths('config_paths', 'Config paths')
  elseif a ==# 'edit_log_paths'
    call s:edit_paths('log_paths', 'Log paths')
  elseif a ==# 'edit_script_paths'
    call s:edit_paths('script_paths', 'Script paths')
  elseif a ==# 'edit_ignore'
    call s:edit_paths('ignore', 'Ignore patterns')
  elseif a ==# 'set_ssh_config'
    call s:prompt_str('ssh_config', 'SSH config')

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
function! s:prompt_str(key, label) abort
  let cur = get(g:neofinder, a:key, '')
  call inputsave()
  let val = input(a:label . ': ', cur, 'file')
  call inputrestore()
  if val !=# ''
    let g:neofinder[a:key] = expand(val)
  endif
endfunction

function! s:edit_paths(key, label) abort
  call s:close_panel()
  let paths = copy(get(g:neofinder, a:key, []))
  let home = expand('~')

  while 1
    redraw
    echo '  ' . a:label . ':'
    let idx = 0
    for p in paths
      let idx += 1
      echo printf('  %d) %s', idx, substitute(p, '^' . home, '~', ''))
    endfor
    if empty(paths) | echo '  (empty)' | endif
    echo ''
    echo '  a=add  d<#>=delete  Enter=done'

    call inputsave()
    let c = input('> ')
    call inputrestore()

    if c ==# ''
      break
    elseif c ==# 'a'
      call inputsave()
      let p = input('  Path: ', '', 'dir')
      call inputrestore()
      if p !=# ''
        call add(paths, expand(p))
      endif
    elseif c =~# '^d\s*\d\+$'
      let n = str2nr(matchstr(c, '\d\+'))
      if n >= 1 && n <= len(paths)
        call remove(paths, n - 1)
      endif
    endif
  endwhile

  let g:neofinder[a:key] = paths
  call s:reopen()
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
