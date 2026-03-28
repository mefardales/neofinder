" neofinder#config  -- Settings panel & configuration interface
"
" Provides an interactive config menu triggered by :NeoConfig or <F1> inside
" the finder.  Supports theme switching, statusline toggle, preview toggle,
" and custom theme creation.
"
" Works on Vim 8+ and Neovim (buffer-based panel, no popups required).

" ---------------------------------------------------------------------------
" State for the config panel
" ---------------------------------------------------------------------------
let s:config_bufnr = -1
let s:config_winid = -1
let s:config_cursor = 0

" Menu items -- each is [label, action_function_name]
let s:menu_items = []

" ---------------------------------------------------------------------------
" open() -- launch the config panel (standalone or from within finder)
" ---------------------------------------------------------------------------
function! neofinder#config#open() abort
  " Build menu items dynamically
  call s:build_menu()
  call s:create_panel()
  call s:render_panel()
  call s:panel_loop()
endfunction

" ---------------------------------------------------------------------------
" Build the menu items list
" ---------------------------------------------------------------------------
function! s:build_menu() abort
  let s:config_cursor = 0
  let s:menu_items = []

  " Section: Display
  call add(s:menu_items, {'label': '--- DISPLAY ---', 'type': 'header'})

  let sl = &laststatus
  call add(s:menu_items, {
        \ 'label': printf('  Statusline (laststatus):  %s',
        \   sl == 2 ? 'ON (always)' : sl == 1 ? 'ON (split)' : 'OFF'),
        \ 'type': 'action', 'action': 'toggle_statusline'})

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

  " Section: Themes
  call add(s:menu_items, {'label': '', 'type': 'separator'})
  call add(s:menu_items, {'label': '--- THEMES ---', 'type': 'header'})

  let current_theme = get(g:neofinder, 'theme', 'matrix')
  let themes = neofinder#theme#list()
  for t in themes
    let marker = (t ==# current_theme) ? ' *' : '  '
    call add(s:menu_items, {
          \ 'label': printf('  %s%s', t, marker),
          \ 'type': 'action', 'action': 'switch_theme', 'value': t})
  endfor

  " Section: Custom themes
  call add(s:menu_items, {'label': '', 'type': 'separator'})
  call add(s:menu_items, {
        \ 'label': '  + Create custom theme from current...',
        \ 'type': 'action', 'action': 'create_theme'})
  call add(s:menu_items, {
        \ 'label': '  + Edit custom theme file...',
        \ 'type': 'action', 'action': 'edit_theme'})

  " Section: Info
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
" Create the panel buffer
" ---------------------------------------------------------------------------
function! s:create_panel() abort
  call s:close_panel()
  botright new
  let s:config_bufnr = bufnr('%')
  let s:config_winid = win_getid()

  let panel_height = len(s:menu_items) + 4
  execute 'resize ' . min([panel_height, 25])

  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
  setlocal nowrap nonumber norelativenumber nospell
  setlocal nocursorline nocursorcolumn
  setlocal filetype=neofinder-config

  call neofinder#theme#apply()
  call neofinder#theme#set_buffer_highlights()
endfunction

" ---------------------------------------------------------------------------
" Close the panel
" ---------------------------------------------------------------------------
function! s:close_panel() abort
  if s:config_bufnr > 0 && bufexists(s:config_bufnr)
    execute 'bwipeout! ' . s:config_bufnr
  endif
  let s:config_bufnr = -1
  let s:config_winid = -1
endfunction

" ---------------------------------------------------------------------------
" Render the panel contents
" ---------------------------------------------------------------------------
function! s:render_panel() abort
  if s:config_bufnr < 0 || !bufexists(s:config_bufnr)
    return
  endif
  let winid = bufwinid(s:config_bufnr)
  if winid < 0
    return
  endif
  call win_gotoid(winid)

  setlocal modifiable
  silent! %delete _

  call setline(1, '  NeoFinder Settings                    [q/Esc] close  [Enter] select')
  call setline(2, repeat('=', 72))

  let lnum = 3
  for i in range(len(s:menu_items))
    let item = s:menu_items[i]
    let pointer = ''
    if item.type ==# 'action' && i == s:config_cursor
      let pointer = '> '
    elseif item.type ==# 'action'
      let pointer = '  '
    endif
    call setline(lnum, pointer . item.label)
    let lnum += 1
  endfor

  setlocal nomodifiable

  " Highlighting
  call clearmatches()
  call matchadd('NeoFinderPrompt', '\%1l')
  call matchadd('NeoFinderBorder', '\%2l')
  " Headers
  call matchadd('NeoFinderStatus', '^--- .\+ ---$')
  " Active theme marker
  call matchadd('NeoFinderSelected', ' \*$')
  " Cursor line
  let cursor_lnum = s:cursor_to_lnum()
  if cursor_lnum > 0
    call matchadd('NeoFinderCursor', '\%' . cursor_lnum . 'l')
  endif
endfunction

" ---------------------------------------------------------------------------
" Map config_cursor to a buffer line number
" ---------------------------------------------------------------------------
function! s:cursor_to_lnum() abort
  return s:config_cursor + 3  " +3 for title + separator lines
endfunction

" ---------------------------------------------------------------------------
" Move cursor to next/prev actionable item
" ---------------------------------------------------------------------------
function! s:move_cursor(dir) abort
  let n = len(s:menu_items)
  let pos = s:config_cursor + a:dir
  while pos >= 0 && pos < n
    if s:menu_items[pos].type ==# 'action'
      let s:config_cursor = pos
      return
    endif
    let pos += a:dir
  endwhile
endfunction

" Ensure cursor starts on an actionable item
function! s:snap_cursor() abort
  if s:config_cursor < len(s:menu_items) && s:menu_items[s:config_cursor].type ==# 'action'
    return
  endif
  call s:move_cursor(1)
endfunction

" ---------------------------------------------------------------------------
" Panel input loop
" ---------------------------------------------------------------------------
function! s:panel_loop() abort
  call s:snap_cursor()
  call s:render_panel()

  while 1
    redraw
    echo ''
    let c = getchar()
    if type(c) == type(0)
      let ch = nr2char(c)
    else
      let ch = c
    endif

    " Quit
    if c == 27 || c == 3 || ch ==# 'q'
      call s:close_panel()
      return
    endif

    " Enter → execute action
    if c == 13
      call s:execute_action()
      " Rebuild and re-render after action
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
" Execute the action under cursor
" ---------------------------------------------------------------------------
function! s:execute_action() abort
  let item = s:menu_items[s:config_cursor]
  if item.type !=# 'action'
    return
  endif

  let action = item.action

  if action ==# 'toggle_statusline'
    call s:toggle_statusline()
  elseif action ==# 'toggle_preview'
    let g:neofinder.preview = !get(g:neofinder, 'preview', 1)
  elseif action ==# 'change_preview_width'
    call s:prompt_number('preview_width', 'Preview width (columns)', 20, 120)
  elseif action ==# 'change_height'
    call s:prompt_number('height', 'Finder height (lines)', 5, 40)
  elseif action ==# 'switch_theme'
    let g:neofinder.theme = item.value
    call neofinder#theme#apply()
    " Re-apply to current panel
    call neofinder#theme#set_buffer_highlights()
  elseif action ==# 'create_theme'
    call s:create_custom_theme()
  elseif action ==# 'edit_theme'
    call s:edit_custom_theme()
  endif
endfunction

" ---------------------------------------------------------------------------
" Toggle statusline (laststatus 0 → 2 → 0)
" ---------------------------------------------------------------------------
function! s:toggle_statusline() abort
  if &laststatus == 0
    set laststatus=2
  else
    set laststatus=0
  endif
endfunction

" ---------------------------------------------------------------------------
" Prompt for a numeric value
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
  " Re-open panel
  call s:build_menu()
  call s:create_panel()
  call s:snap_cursor()
  call s:render_panel()
endfunction

" ---------------------------------------------------------------------------
" Create a custom theme from the current theme
" ---------------------------------------------------------------------------
function! s:create_custom_theme() abort
  call s:close_panel()
  let name = input('New theme name: ')
  if name ==# '' || name =~# '[^a-zA-Z0-9_-]'
    echo "\n  Invalid name (use letters, digits, - and _ only)"
    return
  endif
  " Copy current theme as base
  let current = get(g:neofinder, 'theme', 'matrix')
  let base = deepcopy(neofinder#theme#get(current))
  let path = neofinder#theme#save(name, base)
  echohl NeoFinderPrompt
  echo printf("\n  Theme '%s' saved to %s", name, path)
  echo '  Edit the file to customize colors, then use :NeoConfig to switch.'
  echohl None
endfunction

" ---------------------------------------------------------------------------
" Open a custom theme file for editing
" ---------------------------------------------------------------------------
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
  " List theme files and let user pick
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

" ---------------------------------------------------------------------------
" open_from_finder() -- called when <F1> is pressed inside the finder
"   Closes finder, opens config, reopens finder after config closes.
" ---------------------------------------------------------------------------
function! neofinder#config#open_from_finder(source) abort
  call neofinder#config#open()
endfunction
