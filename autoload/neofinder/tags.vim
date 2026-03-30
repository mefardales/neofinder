" neofinder#tags  -- persistent file tagging with groups
"
" Format: one entry per line in ~/.neofinder/tags
"   group:full/path/to/file
"
" Files without a group prefix are treated as group 'default'.

" ---------------------------------------------------------------------------
" Ensure tag directory and file exist
" ---------------------------------------------------------------------------
function! s:ensure_tag_file() abort
  let tagfile = get(g:neofinder, 'tag_file', expand('~/.neofinder/tags'))
  let dir = fnamemodify(tagfile, ':h')
  if !isdirectory(dir)
    call mkdir(dir, 'p', 0700)
  endif
  if !filereadable(tagfile)
    call writefile([], tagfile)
  endif
  return tagfile
endfunction

" ---------------------------------------------------------------------------
" Parse a line → [group, path]
" ---------------------------------------------------------------------------
function! s:parse_line(line) abort
  let idx = stridx(a:line, ':')
  " On Windows, skip single-letter drive prefixes like C:
  if idx == 1 && a:line[0] =~# '[A-Za-z]'
    let idx = stridx(a:line, ':', 2)
  endif
  if idx > 0 && a:line[:idx-1] !~# '[/\\]'
    return [a:line[:idx-1], a:line[idx+1:]]
  endif
  return ['default', a:line]
endfunction

" ---------------------------------------------------------------------------
" Read all tags as raw lines (non-empty)
" ---------------------------------------------------------------------------
function! s:read_raw() abort
  let tagfile = s:ensure_tag_file()
  return filter(readfile(tagfile), 'v:val !=# ""')
endfunction

" ---------------------------------------------------------------------------
" Write raw lines back
" ---------------------------------------------------------------------------
function! s:write_raw(lines) abort
  let tagfile = s:ensure_tag_file()
  call writefile(a:lines, tagfile)
endfunction

" ---------------------------------------------------------------------------
" list()  -- flat list of all paths (for backward compat with sources.vim)
" ---------------------------------------------------------------------------
function! neofinder#tags#list() abort
  let result = []
  for line in s:read_raw()
    let [grp, path] = s:parse_line(line)
    call add(result, path)
  endfor
  return result
endfunction

" ---------------------------------------------------------------------------
" list_groups()  -- list of unique group names
" ---------------------------------------------------------------------------
function! neofinder#tags#list_groups() abort
  let groups = {}
  for line in s:read_raw()
    let [grp, path] = s:parse_line(line)
    let groups[grp] = get(groups, grp, 0) + 1
  endfor
  let result = []
  for [name, cnt] in items(groups)
    call add(result, name . '  (' . cnt . ' files)')
  endfor
  return sort(result)
endfunction

" ---------------------------------------------------------------------------
" list_by_group({group})  -- files in a specific group
" ---------------------------------------------------------------------------
function! neofinder#tags#list_by_group(group) abort
  let result = []
  for line in s:read_raw()
    let [grp, path] = s:parse_line(line)
    if grp ==# a:group
      call add(result, path)
    endif
  endfor
  return result
endfunction

" ---------------------------------------------------------------------------
" add({path} [, {group}])
" ---------------------------------------------------------------------------
function! neofinder#tags#add(path, ...) abort
  let group = a:0 ? a:1 : 'default'
  if group ==# ''
    let group = 'default'
  endif
  let fullpath = fnamemodify(a:path, ':p')
  let raw = s:read_raw()

  " Check if already tagged in this group
  for line in raw
    let [grp, path] = s:parse_line(line)
    if grp ==# group && path ==# fullpath
      echohl NeoFinderStatus
      echo '  [NeoFinder] Already tagged in [' . group . ']: ' . fnamemodify(fullpath, ':t')
      echohl None
      return
    endif
  endfor

  call add(raw, group . ':' . fullpath)
  call s:write_raw(raw)
  echohl NeoFinderPrompt
  echo '  [NeoFinder] Tagged [' . group . ']: ' . fnamemodify(fullpath, ':t')
  echohl None
endfunction

" ---------------------------------------------------------------------------
" remove({path})  -- remove from ALL groups
" ---------------------------------------------------------------------------
function! neofinder#tags#remove(path) abort
  let fullpath = fnamemodify(a:path, ':p')
  let raw = s:read_raw()
  let new_raw = []
  let found = 0
  for line in raw
    let [grp, path] = s:parse_line(line)
    if path ==# fullpath
      let found = 1
    else
      call add(new_raw, line)
    endif
  endfor
  if found
    call s:write_raw(new_raw)
    echohl NeoFinderPrompt
    echo '  [NeoFinder] Untagged: ' . fnamemodify(fullpath, ':t')
    echohl None
  else
    echohl NeoFinderStatus
    echo '  [NeoFinder] Not tagged: ' . fnamemodify(fullpath, ':t')
    echohl None
  endif
endfunction

" ---------------------------------------------------------------------------
" tag_current()  -- tag current file, ask for group
" ---------------------------------------------------------------------------
function! neofinder#tags#tag_current() abort
  let path = expand('%:p')
  if path ==# ''
    echohl ErrorMsg
    echo '  [NeoFinder] No file in current buffer'
    echohl None
    return
  endif
  let group = input('Tag group (default): ')
  redraw
  call neofinder#tags#add(path, group)
endfunction

" ---------------------------------------------------------------------------
" untag_current()  -- untag current file from all groups
" ---------------------------------------------------------------------------
function! neofinder#tags#untag_current() abort
  let path = expand('%:p')
  if path ==# ''
    echohl ErrorMsg
    echo '  [NeoFinder] No file in current buffer'
    echohl None
    return
  endif
  call neofinder#tags#remove(path)
endfunction

" ---------------------------------------------------------------------------
" extract_group_name({display_line})  -- parse "groupname  (N files)"
" ---------------------------------------------------------------------------
function! neofinder#tags#extract_group_name(line) abort
  return matchstr(a:line, '^\S\+')
endfunction
