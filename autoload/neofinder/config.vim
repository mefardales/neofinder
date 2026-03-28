" neofinder#config  -- Settings panel & configuration interface
"
" Provides an interactive config menu triggered by :NeoConfig or <F1>.
" Supports theme switching (affects ALL of Vim), statusline toggle,
" preview toggle, and custom theme creation.

let s:config_bufnr = -1
let s:config_winid = -1
let s:config_cursor = 0
let s:menu_items = []

" ---------------------------------------------------------------------------
" open()
" ---------------------------------------------------------------------------
function! neofinder#config#open() abort
  call s:build_menu()
  call s:create_panel()
  call s:render_panel()
  call s:panel_loop()
endfunction

" ---------------------------------------------------------------------------
" Build the menu
" ---------------------------------------------------------------------------
function! s:build_menu() abort
  let s:config_cursor = 0
  let s:menu_items = []

  " -- EDITOR --
  call add(s:menu_items, {'label': '--- EDITOR (global) ---', 'type': 'header'})

  let sl_active = &statusline =~# 'neofinder#statusline'
  call add(s:menu_items, {
        \ 'label': printf('  NeoFinder Statusline:  %s', sl_active ? 'ON' : 'OFF'),
        \ 'type': 'action', 'action': 'toggle_statusline'})

  let ls = &laststatus
  call add(s:menu_items, {
        \ 'label': printf('  laststatus:  %d (%s)',
        \   ls, ls == 2 ? 'always' : ls == 1 ? 'on split' : 'never'),
        \ 'type': 'action', 'action': 'cycle_laststatus'})

  call add(s:menu_items, {
        \ 'label': printf('  Line numbers:  %s',
        \   &number ? 'ON' . (&relativenumber ? ' (relative)' : '') : 'OFF'),
        \ 'type': 'action', 'action': 'toggle_numbers'})

  call add(s:menu_items, {
        \ 'label': printf('  Cursor line highlight:  %s', &cursorline ? 'ON' : 'OFF'),
        \ 'type': 'action', 'action': 'toggle_cursorline'})

  " -- FINDER --
  call add(s:menu_items, {'label': '', 'type': 'separator'})
  call add(s:menu_items, {'label': '--- NEOFINDER UI ---', 'type': 'header'})

  let pv = get(g:neofinder, 'preview', 1)
  call add(s:menu_items, {
        \ 'label': printf('  Preview pane:  %s', pv ? 'ON' : 'OFF'),
        \ 'type': 'action', 'action': 'toggle_preview'})

  call add(s:menu_items, {
        \ 'label': printf('  Preview width:  %d columns', get(g:neofinder, 'preview_width', 60)),
        \ 'type': 'action', 'action': 'change_preview_width'})

  call add(s:menu_items, {
        \ 'label': printf('  Finder height:  %d lines', get(g:neofinder, 'height', 15)),
        \ 'type': 'action', 'action': 'change_height'})

  " -- THEMES --
  call add(s:menu_items, {'label': '', 'type': 'separator'})
  call add(s:menu_items, {'label': '--- THEMES (editor + finder + statusline) ---', 'type': 'header'})

  let current_theme = get(g:neofinder, 'theme', 'matrix')
  for t in neofinder#theme#list()
    let marker = (t ==# current_theme) ? '  *' : ''
    call add(s:menu_items, {
          \ 'label': printf('  %s%s', t, marker),
          \ 'type': 'action', 'action': 'switch_theme', 'value': t})
  endfor

  call add(s:menu_items, {'label': '', 'type': 'separator'})
  call add(s:menu_items, {
        \ 'label': '  + Create custom theme from current...',
        \ 'type': 'action', 'action': 'create_theme'})
  call add(s:menu_items, {
        \ 'label': '  + Edit custom theme file...',
        \ 'type': 'action', 'action': 'edit_theme'})

  " -- INFO --
  call add(s:menu_items, {'label': '', 'type': 'separator'})
  call add(s:menu_items, {'label': '--- INFO ---', 'type': 'header'})
  call add(s:menu_items, {
        \ 'label': printf('  Backend:  %s', neofinder#backend()),
        \ 'type': 'info'})
  call add(s:menu_items, {
        \ 'label': printf('  Max files:  %d', get(g:neofinder, 'max_files', 50000)),
        \ 'type': 'info'})
  call add(s:menu_items, {
        \ 'label': printf('  Theme dir:  %s', expand('~/.neofinder/themes/')),
        \ 'type': 'info'})
endfunction

" ---------------------------------------------------------------------------
" Panel buffer
" ---------------------------------------------------------------------------
function! s:create_panel() abort
  call s:close_panel()
  botright new
  let s:config_bufnr = bufnr('%')
  let s:config_winid = win_getid()
  execute 'resize ' . min([len(s:menu_items) + 4, 30])
  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
  setlocal nowrap nonumber norelativenumber nospell
  setlocal nocursorline nocursorcolumn
  setlocal filetype=neofinder-config
  call neofinder#theme#set_buffer_highlights()
endfunction

function! s:close_panel() abort
  if s:config_bufnr > 0 && bufexists(s:config_bufnr)
    execute 'bwipeout! ' . s:config_bufnr
  endif
  let s:config_bufnr = -1
  let s:config_winid = -1
endfunction

" ---------------------------------------------------------------------------
" Render
" ---------------------------------------------------------------------------
function! s:render_panel() abort
  if s:config_bufnr < 0 || !bufexists(s:config_bufnr)
    return
  endif
  call win_gotoid(bufwinid(s:config_bufnr))

  setlocal modifiable
  silent! %delete _

  call setline(1, '  NeoFinder Settings                    [q/Esc] close  [Enter] select')
  call setline(2, repeat('=', 72))

  let lnum = 3
  for i in range(len(s:menu_items))
    let item = s:menu_items[i]
    if item.type ==# 'action'
      let pointer = (i == s:config_cursor) ? '> ' : '  '
    else
      let pointer = ''
    endif
    call setline(lnum, pointer . item.label)
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

" ---------------------------------------------------------------------------
" Navigation
" ---------------------------------------------------------------------------
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

" ---------------------------------------------------------------------------
" Input loop
" ---------------------------------------------------------------------------
function! s:panel_loop() abort
  call s:snap_cursor()
  call s:render_panel()

  while 1
    redraw
    echo ''
    let c = getchar()
    let ch = type(c) == type(0) ? nr2char(c) : c

    " Quit
    if c == 27 || c == 3 || ch ==# 'q'
      call s:close_panel()
      return
    endif

    " Enter
    if c == 13
      call s:execute_action()
      call s:build_menu()
      call s:snap_cursor()
      call s:render_panel()
      continue
    endif

    " Down
    if c == 10 || c == 14 || ch ==# "\<Down>" || ch ==# 'j'
      call s:move_cursor(1)
      call s:render_panel()
      continue
    endif

    " Up
    if c == 11 || c == 16 || ch ==# "\<Up>" || ch ==# 'k'
      call s:move_cursor(-1)
      call s:render_panel()
      continue
    endif
  endwhile
endfunction

" ---------------------------------------------------------------------------
" Execute action
" ---------------------------------------------------------------------------
function! s:execute_action() abort
  let item = s:menu_items[s:config_cursor]
  if item.type !=# 'action'
    return
  endif
  let action = item.action

  if action ==# 'toggle_statusline'
    call neofinder#statusline#toggle()

  elseif action ==# 'cycle_laststatus'
    " Cycle: 0 → 1 → 2 → 0
    let &laststatus = (&laststatus + 1) % 3

  elseif action ==# 'toggle_numbers'
    if &number && &relativenumber
      set norelativenumber
    elseif &number
      set nonumber
    else
      set number
    endif

  elseif action ==# 'toggle_cursorline'
    set cursorline!

  elseif action ==# 'toggle_preview'
    let g:neofinder.preview = !get(g:neofinder, 'preview', 1)

  elseif action ==# 'change_preview_width'
    call s:prompt_number('preview_width', 'Preview width (columns)', 20, 120)

  elseif action ==# 'change_height'
    call s:prompt_number('height', 'Finder height (lines)', 5, 40)

  elseif action ==# 'switch_theme'
    let g:neofinder.theme = item.value
    call neofinder#theme#apply()
    " Re-apply panel highlights after global theme change
    call neofinder#theme#set_buffer_highlights()

  elseif action ==# 'create_theme'
    call s:create_custom_theme()

  elseif action ==# 'edit_theme'
    call s:edit_custom_theme()
  endif
endfunction

" ---------------------------------------------------------------------------
" Helpers
" ---------------------------------------------------------------------------
function! s:prompt_number(key, label, min, max) abort
  call s:close_panel()
  let current = get(g:neofinder, a:key, a:min)
  let val = input(printf('%s [%d-%d] (current: %d): ', a:label, a:min, a:max, current))
  if val =~# '^\d\+$'
    let num = str2nr(val)
    if num >= a:min && num <= a:max
      let g:neofinder[a:key] = num
    endif
  endif
  call s:build_menu()
  call s:create_panel()
  call s:snap_cursor()
  call s:render_panel()
endfunction

function! s:create_custom_theme() abort
  call s:close_panel()
  let name = input('New theme name: ')
  if name ==# '' || name =~# '[^a-zA-Z0-9_-]'
    echo "\n  Invalid name (use letters, digits, - and _ only)"
    return
  endif
  let current = get(g:neofinder, 'theme', 'matrix')
  let base = deepcopy(neofinder#theme#get(current))
  let path = neofinder#theme#save(name, base)
  echohl NeoFinderPrompt
  echo printf("\n  Theme '%s' saved to %s", name, path)
  echo '  Edit the file to customize, then :NeoConfig to switch.'
  echohl None
endfunction

function! s:edit_custom_theme() abort
  let dir = expand('~/.neofinder/themes')
  if !isdirectory(dir)
    call mkdir(dir, 'p', 0700)
  endif
  let files = glob(dir . '/*.vim', 0, 1)
  if empty(files)
    call s:close_panel()
    echo '  No custom themes found. Create one first.'
    return
  endif
  call s:close_panel()
  echo '  Custom themes:'
  let idx = 0
  for f in files
    let idx += 1
    echo printf('  %d) %s', idx, fnamemodify(f, ':t:r'))
  endfor
  let choice = input('Edit theme # (or Enter to cancel): ')
  if choice =~# '^\d\+$' && str2nr(choice) >= 1 && str2nr(choice) <= len(files)
    execute 'edit ' . fnameescape(files[str2nr(choice) - 1])
  endif
endfunction

function! neofinder#config#open_from_finder(source) abort
  call neofinder#config#open()
endfunction
