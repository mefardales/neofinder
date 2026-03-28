" neofinder#buffers  -- buffer manager, tab groups, terminal
"
" Provides tmux-like tab groups with names, buffer listing, and terminal
" integration.  Tab groups are persisted to ~/.neofinder/tabgroups.json.

" ---------------------------------------------------------------------------
" Tab group storage:  { 'groupname': [tabnr, ...], ... }
" ---------------------------------------------------------------------------
let s:tab_groups = {}
let s:groups_loaded = 0

" ---------------------------------------------------------------------------
" Persistence file path
" ---------------------------------------------------------------------------
function! s:groups_file() abort
  let dir = fnamemodify(get(g:neofinder, 'tag_file', expand('~/.neofinder/tags')), ':h')
  return dir . '/tabgroups.json'
endfunction

" ---------------------------------------------------------------------------
" Load groups from disk
" ---------------------------------------------------------------------------
function! s:load_groups() abort
  if s:groups_loaded
    return
  endif
  let s:groups_loaded = 1
  let f = s:groups_file()
  if !filereadable(f)
    return
  endif
  try
    let raw = join(readfile(f), '')
    if exists('*json_decode')
      let s:tab_groups = json_decode(raw)
    else
      " Vim 7.4 fallback: minimal JSON object parse
      " Only handles { "key": [num, ...], ... }
      let s:tab_groups = eval(substitute(raw, ':', ',', 'g'))
    endif
  catch
    let s:tab_groups = {}
  endtry
endfunction

" ---------------------------------------------------------------------------
" Save groups to disk
" ---------------------------------------------------------------------------
function! s:save_groups() abort
  let f = s:groups_file()
  let dir = fnamemodify(f, ':h')
  if !isdirectory(dir)
    call mkdir(dir, 'p', 0700)
  endif
  if exists('*json_encode')
    call writefile([json_encode(s:tab_groups)], f)
  else
    " Vim 7.4 fallback
    call writefile([string(s:tab_groups)], f)
  endif
endfunction

" ---------------------------------------------------------------------------
" list() -- return formatted list of open buffers
" ---------------------------------------------------------------------------
function! neofinder#buffers#list() abort
  let result = []
  for info in getbufinfo({'buflisted': 1})
    let nr = info.bufnr
    let name = info.name !=# '' ? fnamemodify(info.name, ':~:.') : '[No Name]'
    let flags = ''
    if info.changed
      let flags .= ' [+]'
    endif
    if nr == bufnr('%')
      let flags .= ' %'
    elseif nr == bufnr('#')
      let flags .= ' #'
    endif
    call add(result, printf('%3d: %s%s', nr, name, flags))
  endfor
  return result
endfunction

" ---------------------------------------------------------------------------
" list_groups() -- return formatted list of tab groups
" ---------------------------------------------------------------------------
function! neofinder#buffers#list_groups() abort
  call s:load_groups()
  let result = []
  if empty(s:tab_groups)
    return ['(no groups -- use :NeoGroupCreate <name>)']
  endif
  for [name, tabs] in items(s:tab_groups)
    " Clean out stale tab numbers (tabs that no longer exist)
    let valid = filter(copy(tabs), 'index(range(1, tabpagenr("$")), v:val) >= 0')
    let s:tab_groups[name] = valid
    let current = (index(valid, tabpagenr()) >= 0) ? ' *' : ''
    call add(result, printf('[%s] %d tabs%s', name, len(valid), current))
  endfor
  call s:save_groups()
  return result
endfunction

" ---------------------------------------------------------------------------
" create_group({name})
" ---------------------------------------------------------------------------
function! neofinder#buffers#create_group(name) abort
  call s:load_groups()
  let name = substitute(a:name, '^\s\+\|\s\+$', '', 'g')
  if name ==# ''
    echohl ErrorMsg
    echo '  [NeoFinder] Group name required'
    echohl None
    return
  endif
  if has_key(s:tab_groups, name)
    echohl NeoFinderStatus
    echo '  [NeoFinder] Group already exists: ' . name
    echohl None
    return
  endif
  let s:tab_groups[name] = [tabpagenr()]
  call s:save_groups()
  echohl NeoFinderPrompt
  echo '  [NeoFinder] Created group: ' . name . ' (current tab added)'
  echohl None
endfunction

" ---------------------------------------------------------------------------
" add_to_group({name})
" ---------------------------------------------------------------------------
function! neofinder#buffers#add_to_group(name) abort
  call s:load_groups()
  let name = substitute(a:name, '^\s\+\|\s\+$', '', 'g')
  if !has_key(s:tab_groups, name)
    echohl ErrorMsg
    echo '  [NeoFinder] Group not found: ' . name
    echohl None
    return
  endif
  let tabnr = tabpagenr()
  if index(s:tab_groups[name], tabnr) < 0
    call add(s:tab_groups[name], tabnr)
    call s:save_groups()
    echohl NeoFinderPrompt
    echo printf('  [NeoFinder] Tab %d added to group: %s', tabnr, name)
    echohl None
  else
    echohl NeoFinderStatus
    echo printf('  [NeoFinder] Tab %d already in group: %s', tabnr, name)
    echohl None
  endif
endfunction

" ---------------------------------------------------------------------------
" remove_from_group({name})
" ---------------------------------------------------------------------------
function! neofinder#buffers#remove_from_group(name) abort
  call s:load_groups()
  let name = substitute(a:name, '^\s\+\|\s\+$', '', 'g')
  if !has_key(s:tab_groups, name)
    echohl ErrorMsg
    echo '  [NeoFinder] Group not found: ' . name
    echohl None
    return
  endif
  let tabnr = tabpagenr()
  let idx = index(s:tab_groups[name], tabnr)
  if idx >= 0
    call remove(s:tab_groups[name], idx)
    call s:save_groups()
    echohl NeoFinderPrompt
    echo printf('  [NeoFinder] Tab %d removed from group: %s', tabnr, name)
    echohl None
  else
    echohl NeoFinderStatus
    echo printf('  [NeoFinder] Tab %d not in group: %s', tabnr, name)
    echohl None
  endif
endfunction

" ---------------------------------------------------------------------------
" switch_to_group({name}) -- go to the first tab in the group
" ---------------------------------------------------------------------------
function! neofinder#buffers#switch_to_group(name) abort
  call s:load_groups()
  if !has_key(s:tab_groups, name)
    echohl ErrorMsg
    echo '  [NeoFinder] Group not found: ' . name
    echohl None
    return
  endif
  let tabs = s:tab_groups[name]
  " Clean stale tab numbers
  let valid = filter(copy(tabs), 'index(range(1, tabpagenr("$")), v:val) >= 0')
  let s:tab_groups[name] = valid
  call s:save_groups()
  if empty(valid)
    echohl NeoFinderStatus
    echo '  [NeoFinder] Group "' . name . '" has no active tabs'
    echohl None
    return
  endif
  execute 'tabnext ' . valid[0]
endfunction

" ---------------------------------------------------------------------------
" extract_group_name({line}) -- parse group name from "[name] N tabs" format
" ---------------------------------------------------------------------------
function! neofinder#buffers#extract_group_name(line) abort
  let m = matchstr(a:line, '^\[\zs[^\]]\+\ze\]')
  return m
endfunction

" ---------------------------------------------------------------------------
" extract_bufnr({line}) -- parse buffer number from "  3: filename" format
" ---------------------------------------------------------------------------
function! neofinder#buffers#extract_bufnr(line) abort
  let m = matchstr(a:line, '^\s*\zs\d\+\ze:')
  return str2nr(m)
endfunction

" ---------------------------------------------------------------------------
" open_terminal([{cmd}]) -- open a terminal, optionally run a command
" ---------------------------------------------------------------------------
function! neofinder#buffers#open_terminal(...) abort
  let cmd = a:0 ? a:1 : ''
  if has('nvim')
    if cmd !=# ''
      execute 'botright split | terminal ' . cmd
    else
      execute 'botright split | terminal'
    endif
    startinsert
  elseif exists(':terminal')
    if cmd !=# ''
      execute 'botright terminal ++rows=15 ' . cmd
    else
      execute 'botright terminal ++rows=15'
    endif
  else
    if cmd !=# ''
      execute '!' . cmd
    else
      shell
    endif
  endif
endfunction

" ---------------------------------------------------------------------------
" group_names() -- return list of group names (for command completion)
" ---------------------------------------------------------------------------
function! neofinder#buffers#group_names(A, L, P) abort
  call s:load_groups()
  return filter(keys(s:tab_groups), 'v:val =~# "^" . a:A')
endfunction
