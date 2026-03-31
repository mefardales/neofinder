" neofinder#core  -- fuzzy matching engine, buffer-based UI, multi-select
"
" Works on Vim 7.4+ (buffer-based), Vim 8+ (popup if available), Neovim.
"
" Navigation stack: when you enter a source from the palette, Backspace
" on an empty query goes back to the palette.  Esc always closes fully.

" ---------------------------------------------------------------------------
" State
" ---------------------------------------------------------------------------
let s:state = {
      \ 'source':    '',
      \ 'items':     [],
      \ 'filtered':  [],
      \ 'query':     '',
      \ 'cursor':    0,
      \ 'selected':  {},
      \ 'bufnr':     -1,
      \ 'prevbuf':   -1,
      \ 'preview_bufnr': -1,
      \ }

" Navigation history stack  (list of source names)
let s:nav_stack = []

" Directory browser state
let s:browse_dir = ''
let s:browse_history = []

" Tab-toggle state: when 1, input_loop exited to give focus to editor
let s:toggled_to_editor = 0

" ---------------------------------------------------------------------------
" Fuzzy match scoring
" ---------------------------------------------------------------------------
function! s:fuzzy_score(pattern, str) abort
  if a:pattern ==# ''
    return 1000
  endif
  let pat = tolower(a:pattern)
  let str = tolower(a:str)
  let pi = 0
  let score = 0
  let last_match = -1
  let consecutive = 0
  for si in range(len(str))
    if pi < len(pat) && str[si] ==# pat[pi]
      let score += 10
      if last_match == si - 1
        let consecutive += 1
        let score += consecutive * 5
      else
        let consecutive = 0
      endif
      if si == 0 || str[si - 1] =~# '[/_.\- ]'
        let score += 15
      endif
      let last_match = si
      let pi += 1
    endif
  endfor
  if pi < len(pat)
    return -1
  endif
  let score -= len(str) / 5
  return score
endfunction

let s:max_filter_results = 500

function! s:filter_items(items, query) abort
  if a:query ==# ''
    return copy(a:items)
  endif

  " Glob mode: if query contains * or ?
  if a:query =~# '[*?]'
    return s:filter_glob(a:items, a:query)
  endif

  " Fuzzy mode with early exit
  let scored = []
  let limit = s:max_filter_results
  for item in a:items
    let sc = s:fuzzy_score(a:query, item)
    if sc >= 0
      call add(scored, [sc, item])
    endif
  endfor
  call sort(scored, {a, b -> b[0] - a[0]})
  if len(scored) > limit
    let scored = scored[:limit - 1]
  endif
  return map(scored, 'v:val[1]')
endfunction

function! s:filter_glob(items, pattern) abort
  let pat = a:pattern
  let pat = substitute(pat, '\.', '\\.', 'g')
  let pat = substitute(pat, '\*\*', '@@DSTAR@@', 'g')
  let pat = substitute(pat, '\*', '[^/]*', 'g')
  let pat = substitute(pat, '@@DSTAR@@', '.*', 'g')
  let pat = substitute(pat, '?', '.', 'g')
  let regex = '\c' . pat . '$'

  let results = []
  let limit = s:max_filter_results
  for item in a:items
    if item =~# regex
      call add(results, item)
      if len(results) >= limit | break | endif
    endif
  endfor
  return results
endfunction

" ---------------------------------------------------------------------------
" run({source}, {items}, {initial_query})
" ---------------------------------------------------------------------------
function! neofinder#core#run(source, items, query) abort
  let s:state.source = a:source
  let s:state.items = a:items
  let s:state.query = a:query
  let s:state.cursor = 0
  let s:state.selected = {}
  let s:state.prevbuf = bufnr('%')

  " Initialize directory browser state
  if a:source ==# 'browse'
    let s:browse_dir = get(g:neofinder, '_browse_dir', getcwd())
    let s:browse_history = []
  endif

  call neofinder#theme#apply()

  call s:create_buffer()
  call s:refilter()
  call s:redraw()

  call s:input_loop()

  " Tab-toggle loop: if user toggled to editor, wait for Tab to come back
  while s:toggled_to_editor
    let s:toggled_to_editor = 0
    let finder_winid = bufwinid(s:state.bufnr)
    let prev_winid = bufwinid(s:state.prevbuf)

    " Move focus to editor
    if prev_winid > 0
      call win_gotoid(prev_winid)
    else
      wincmd p
    endif

    " Set Tab mapping in editor to return to finder
    nnoremap <buffer> <silent> <Tab> :call neofinder#core#resume_from_editor()<CR>

    " Vim returns to normal mode in the editor.
    " resume_from_editor() handles the return via Tab.
    return
  endwhile
endfunction

" ---------------------------------------------------------------------------
" run_from_palette({source}, {items}, {query})
"   Like run() but pushes 'palette' onto the nav stack so backspace returns.
" ---------------------------------------------------------------------------
function! neofinder#core#run_from_palette(source, items, query) abort
  " Push 'palette' as parent so we can go back
  call add(s:nav_stack, 'palette')
  call neofinder#core#run(a:source, a:items, a:query)
endfunction

" ---------------------------------------------------------------------------
" Buffer creation -- simple split at the bottom
" ---------------------------------------------------------------------------
function! s:create_buffer() abort
  let height = get(g:neofinder, 'height', 15)

  call s:cleanup()

  botright new
  let s:state.bufnr = bufnr('%')
  execute 'resize ' . (height + 2)

  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
  setlocal nowrap nonumber norelativenumber nospell
  setlocal nocursorline nocursorcolumn winfixheight
  setlocal filetype=neofinder

  " Finder-specific statusline (different from editor statusline)
  setlocal statusline=%!neofinder#core#finder_statusline()

  call neofinder#theme#set_buffer_highlights()
endfunction

" ---------------------------------------------------------------------------
" Cleanup
" ---------------------------------------------------------------------------
function! s:cleanup() abort
  call neofinder#preview#close()
  if s:state.bufnr > 0 && bufexists(s:state.bufnr)
    execute 'bwipeout! ' . s:state.bufnr
  endif
  let s:state.bufnr = -1
endfunction

" ---------------------------------------------------------------------------
" Go back to parent in nav stack (returns 1 if navigated back, 0 if empty)
" ---------------------------------------------------------------------------
function! s:go_back() abort
  if empty(s:nav_stack)
    return 0
  endif
  let parent = remove(s:nav_stack, -1)
  call s:cleanup()
  if parent ==# 'palette'
    call neofinder#palette('')
  else
    call neofinder#open(parent, '')
  endif
  return 1
endfunction

" ---------------------------------------------------------------------------
" Refilter items
" ---------------------------------------------------------------------------
function! s:refilter() abort
  " Browse + query + Python indexer = search entire project tree
  if s:state.source ==# 'browse' && s:state.query !=# '' && has('python3')
    let dir = get(g:neofinder, '_browse_dir', getcwd())
    " Lazy start indexer on first search
    if neofinder#indexer#count(dir) == 0 && !neofinder#indexer#is_indexing()
      call neofinder#indexer#start(dir)
    endif
    let results = neofinder#indexer#search(dir, s:state.query)
    if !empty(results)
      let s:state.filtered = results
      if s:state.cursor >= len(s:state.filtered)
        let s:state.cursor = max([0, len(s:state.filtered) - 1])
      endif
      return
    endif
  endif

  " Default: filter current items list
  let s:state.filtered = s:filter_items(s:state.items, s:state.query)
  if s:state.cursor >= len(s:state.filtered)
    let s:state.cursor = max([0, len(s:state.filtered) - 1])
  endif
endfunction

" ---------------------------------------------------------------------------
" Redraw the finder buffer
" ---------------------------------------------------------------------------
function! s:redraw() abort
  if s:state.bufnr < 0 || !bufexists(s:state.bufnr)
    return
  endif
  let winid = bufwinid(s:state.bufnr)
  if winid < 0
    return
  endif
  call win_gotoid(winid)

  setlocal modifiable
  silent! %delete _

  let height = get(g:neofinder, 'height', 15)
  let filtered = s:state.filtered
  let total = len(s:state.items)
  let matched = len(filtered)
  let cur = s:state.cursor

  " Prompt line
  let prompt = '  >> ' . s:state.query . '_'
  call setline(1, prompt)

  " Status line -- show navigation hints + browse dir
  let backend = neofinder#backend()
  let nav_hint = !empty(s:nav_stack) ? '  [BS] back' : ''
  let tab_hint = '  [Tab] editor'
  if s:state.source ==# 'browse'
    let short_dir = substitute(s:browse_dir, '^' . expand('~'), '~', '')
    let nav_hint = '  [BS] up  [Enter] open  [C-t] tag'
    let idx_count = has('python3') ? neofinder#indexer#count(s:browse_dir) : 0
    let idx_info = idx_count > 0 ? '  idx:' . idx_count : ''
    let status = printf('  [BROWSE] %s  |  %d items%s%s%s',
          \ short_dir, matched, idx_info, nav_hint, tab_hint)
  else
    let status = printf('  [%s] %d/%d  |  %s  |  multi:%d%s%s',
          \ toupper(s:state.source), matched, total, backend,
          \ len(s:state.selected), nav_hint, tab_hint)
  endif
  call setline(2, status)

  " Item lines
  let start = 0
  if cur >= height
    let start = cur - height + 1
  endif
  let end = min([start + height, matched])

  let lnum = 3
  for i in range(start, end - 1)
    let item = filtered[i]
    let marker = has_key(s:state.selected, item) ? ' * ' : '   '
    let pointer = (i == cur) ? '> ' : '  '
    call setline(lnum, pointer . marker . item)
    let lnum += 1
  endfor

  setlocal nomodifiable

  call s:highlight_lines(cur - start + 3)

  " Update preview (skip for palette and help)
  if get(g:neofinder, 'preview', 1)
        \ && s:state.source !=# 'help'
        \ && s:state.source !=# 'palette'
    if cur >= 0 && cur < matched
      let preview_path = filtered[cur]
      " In browse mode, resolve to full path for preview
      if s:state.source ==# 'browse' && s:browse_dir !=# ''
        let preview_path = fnamemodify(s:browse_dir . '/' . preview_path, ':p')
      endif
      call neofinder#preview#show(preview_path, s:state.source)
    endif
  endif
endfunction

" ---------------------------------------------------------------------------
" Highlighting for rendered lines
" ---------------------------------------------------------------------------
function! s:highlight_lines(cursor_line) abort
  if s:state.bufnr < 0
    return
  endif
  call clearmatches()
  call matchadd('NeoFinderPrompt', '\%1l')
  call matchadd('NeoFinderStatus', '\%2l')
  call matchadd('NeoFinderSelected', '^\s*>\?\s\+\*.*$')
  if a:cursor_line >= 3
    call matchadd('NeoFinderCursor', '\%' . a:cursor_line . 'l')
  endif
endfunction

" ---------------------------------------------------------------------------
" Input loop
" ---------------------------------------------------------------------------
function! s:input_loop() abort
  while 1
    redraw
    echo ''
    let c = getchar()

    if type(c) == type(0)
      let ch = nr2char(c)
    else
      let ch = c
    endif

    " Escape → always close everything (hard exit)
    if c == 27
      let s:nav_stack = []
      call s:cleanup()
      return
    endif

    " Ctrl-C → close (same as Esc)
    if c == 3
      let s:nav_stack = []
      call s:cleanup()
      return
    endif

    " Enter → accept (or enter directory in browse mode)
    if c == 13
      if s:state.source ==# 'browse' && s:state.cursor < len(s:state.filtered)
        let item = s:state.filtered[s:state.cursor]
        if item =~# '/$'
          " It's a directory → navigate into it
          call s:browse_enter(item)
          continue
        endif
      endif
      call s:accept('edit')
      return
    endif

    " Ctrl-V → vertical split
    if c == 22
      call s:accept('vsplit')
      return
    endif

    " Ctrl-X → horizontal split
    if c == 24
      call s:accept('split')
      return
    endif

    " Ctrl-S → sudoedit
    if c == 19
      call s:accept('sudo')
      return
    endif

    " Ctrl-T → tag current item to a group
    if c == 20
      if s:state.cursor >= 0 && s:state.cursor < len(s:state.filtered)
        let item = s:state.filtered[s:state.cursor]
        " Resolve full path for browse mode
        if s:state.source ==# 'browse' && s:browse_dir !=# ''
          let item = fnamemodify(s:browse_dir . '/' . item, ':p')
        endif
        " Don't tag directories
        if item !~# '/$'
          let group = input('Tag group (default): ')
          redraw
          call neofinder#tags#add(item, group)
          sleep 400m
        endif
      endif
      call s:redraw()
      continue
    endif

    " Ctrl-R → refresh (clear cache, re-scan)
    if c == 18
      call neofinder#sources#invalidate_cache()
      if has('python3')
        call neofinder#indexer#clear()
        call neofinder#indexer#start(get(g:neofinder, '_browse_dir', getcwd()))
      endif
      let s:state.items = neofinder#sources#gather(s:state.source)
      call s:refilter()
      call s:redraw()
      echohl NeoFinderPrompt | echo '  Refreshed' | echohl None
      continue
    endif

    " Ctrl-H → ssh (only when source is 'hosts')
    if c == 8 && s:state.source ==# 'hosts'
      call s:accept('ssh')
      return
    endif

    " Backspace (127 or special key)
    if c == 127 || c == "\<BS>"
      if len(s:state.query) > 0
        " Normal backspace: delete last char
        let s:state.query = s:state.query[:-2]
        call s:refilter()
        call s:redraw()
      elseif s:state.source ==# 'browse' && !empty(s:browse_history)
        " Browse mode: go up to parent directory
        call s:browse_go_up()
      else
        " Empty query + backspace → go back to parent (or close)
        if s:go_back()
          return
        endif
        " No parent, do nothing (Esc to close)
      endif
      continue
    endif

    " Down: Ctrl-J / Ctrl-N / Arrow Down
    if c == 10 || c == 14 || ch ==# "\<Down>"
      if s:state.cursor < len(s:state.filtered) - 1
        let s:state.cursor += 1
      endif
      call s:redraw()
      continue
    endif

    " Up: Ctrl-K / Ctrl-P / Arrow Up
    if c == 11 || c == 16 || ch ==# "\<Up>"
      if s:state.cursor > 0
        let s:state.cursor -= 1
      endif
      call s:redraw()
      continue
    endif

    " Tab → toggle focus to editor (user can press Tab again to return)
    if c == 9
      let s:toggled_to_editor = 1
      return
    endif

    " Ctrl-Space → toggle multi-select (not in palette)
    if c == 0 && s:state.source !=# 'palette'
      if s:state.cursor < len(s:state.filtered)
        let item = s:state.filtered[s:state.cursor]
        if has_key(s:state.selected, item)
          call remove(s:state.selected, item)
        else
          let s:state.selected[item] = 1
        endif
        if s:state.cursor < len(s:state.filtered) - 1
          let s:state.cursor += 1
        endif
      endif
      call s:redraw()
      continue
    endif

    " Ctrl-A → select all (not in palette)
    if c == 1 && s:state.source !=# 'palette'
      for item in s:state.filtered
        let s:state.selected[item] = 1
      endfor
      call s:redraw()
      continue
    endif

    " Ctrl-D → context action: delete buffer / untag / deselect
    if c == 4
      if s:state.source ==# 'buffers' && s:state.cursor < len(s:state.filtered)
        let item = s:state.filtered[s:state.cursor]
        let nr = neofinder#buffers#extract_bufnr(item)
        if nr > 0 && bufexists(nr)
          execute 'bwipeout ' . nr
          let s:state.items = neofinder#sources#gather('buffers')
          call s:refilter()
        endif
      elseif s:state.source ==# 'tags' && s:state.cursor < len(s:state.filtered)
        let item = s:state.filtered[s:state.cursor]
        call neofinder#tags#remove(item)
        let s:state.items = neofinder#tags#list()
        call s:refilter()
      elseif s:state.source ==# 'favorites' && s:state.cursor < len(s:state.filtered)
        let item = s:state.filtered[s:state.cursor]
        if item !~# '^\[+\]'
          call neofinder#tags#remove_favorite(item)
          let s:state.items = neofinder#sources#gather('favorites')
          call s:refilter()
        endif
      else
        let s:state.selected = {}
      endif
      call s:redraw()
      continue
    endif

    " Resize finder panel: Ctrl-W +/- (standard Vim window resize)
    if c == 23
      " Ctrl-W pressed, get next char for sub-command
      let c2 = getchar()
      let ch2 = type(c2) == type(0) ? nr2char(c2) : c2
      if ch2 ==# '+' || ch2 ==# '='
        resize +3
      elseif ch2 ==# '-'
        resize -3
      endif
      call s:redraw()
      continue
    endif

    " Right Arrow → shrink preview (more space for file list)
    if ch ==# "\<Right>"
      call s:resize_preview(-8)
      continue
    endif

    " Left Arrow → grow preview (more space for preview)
    if ch ==# "\<Left>"
      call s:resize_preview(8)
      continue
    endif


    " Ctrl-B → open buffer list
    if c == 2
      call s:cleanup()
      let s:nav_stack = []
      let items = neofinder#buffers#list()
      call neofinder#core#run('buffers', items, '')
      return
    endif

    " Printable character → add to query
    if ch =~# '[ -~]'
      let s:state.query .= ch

      " Browse: if query is a path ending in /, navigate there
      if s:state.source ==# 'browse' && s:state.query =~# '/$\|\\$'
        let nav_path = expand(s:state.query)
        if isdirectory(nav_path)
          call add(s:browse_history, s:browse_dir)
          let s:browse_dir = fnamemodify(nav_path, ':p')
          let s:state.items = neofinder#sources#gather_browse(s:browse_dir)
          let s:state.query = ''
          let s:state.cursor = 0
          call s:refilter()
          call s:redraw()
          continue
        endif
      endif

      call s:refilter()
      call s:redraw()
      continue
    endif
  endwhile
endfunction

" ---------------------------------------------------------------------------
" Directory browser: enter a subdirectory
" ---------------------------------------------------------------------------
function! s:browse_enter(dirname) abort
  " Save current dir in history stack
  call add(s:browse_history, s:browse_dir)
  " Navigate into subdirectory
  let s:browse_dir = fnamemodify(s:browse_dir . '/' . substitute(a:dirname, '/$', '', ''), ':p')
  " Refresh items
  let s:state.items = neofinder#sources#gather_browse(s:browse_dir)
  let s:state.query = ''
  let s:state.cursor = 0
  let s:state.selected = {}
  call s:refilter()
  call s:redraw()
endfunction

" ---------------------------------------------------------------------------
" Directory browser: go up to parent directory
" ---------------------------------------------------------------------------
function! s:browse_go_up() abort
  if empty(s:browse_history)
    return
  endif
  let s:browse_dir = remove(s:browse_history, -1)
  let s:state.items = neofinder#sources#gather_browse(s:browse_dir)
  let s:state.query = ''
  let s:state.cursor = 0
  let s:state.selected = {}
  call s:refilter()
  call s:redraw()
endfunction

" ---------------------------------------------------------------------------
" Resize the preview pane by {delta} columns
" ---------------------------------------------------------------------------
function! s:resize_preview(delta) abort
  if !get(g:neofinder, 'preview', 1)
    return
  endif
  let pw = get(g:neofinder, 'preview_width', 60)
  let new_pw = pw + a:delta
  let max_pw = float2nr(&columns * 0.8)
  let min_pw = 20
  let new_pw = max([min_pw, min([new_pw, max_pw])])
  if new_pw == pw
    return
  endif
  let g:neofinder.preview_width = new_pw
  call neofinder#preview#resize(new_pw)
  let pct = float2nr(100.0 * new_pw / &columns)
  redraw
  echohl NeoFinderStatus
  echo printf('  Preview width: %d cols (%d%%)', new_pw, pct)
  echohl None
endfunction

" ---------------------------------------------------------------------------
" Public accessor for state (used by preview.vim, actions.vim)
" ---------------------------------------------------------------------------
function! neofinder#core#state() abort
  return s:state
endfunction

" ---------------------------------------------------------------------------
" Finder statusline (shown only in the finder panel, not the editor)
" ---------------------------------------------------------------------------
function! neofinder#core#finder_statusline() abort
  let src = toupper(s:state.source)
  let sel = len(s:state.selected)

  let s = ''
  " Source label
  let s .= '%#NeoStMode#'
  let s .= ' NEOFINDER '
  let s .= '%#NeoStBranch#'
  let s .= ' ' . src . ' '

  " Selection count
  if sel > 0
    let s .= '%#NeoStModified#'
    let s .= ' ' . sel . ' selected '
  endif

  " Right side: keybinding hints
  let s .= '%#NeoStInfo#'
  let s .= '%='
  let s .= ' Enter:open '
  let s .= '%#NeoStPosition#'
  let s .= ' Tab:editor '
  let s .= '%#NeoStBranch#'
  let s .= ' C-v:vsplit  C-x:split '
  let s .= '%#NeoStClock#'
  let s .= ' Esc:close '

  return s
endfunction

" ---------------------------------------------------------------------------
" Resume finder from editor (called when user presses Tab in editor)
" ---------------------------------------------------------------------------
function! neofinder#core#resume_from_editor() abort
  " Remove the Tab mapping from the editor buffer
  silent! nunmap <buffer> <Tab>

  " Switch back to finder window
  let finder_winid = bufwinid(s:state.bufnr)
  if finder_winid < 0 || !bufexists(s:state.bufnr)
    " Finder was closed while we were in the editor
    return
  endif
  call win_gotoid(finder_winid)

  " Re-enter the input loop
  call s:redraw()
  call s:input_loop()

  " Handle nested toggles (user may Tab away again)
  while s:toggled_to_editor
    let s:toggled_to_editor = 0
    let prev_winid = bufwinid(s:state.prevbuf)
    if prev_winid > 0
      call win_gotoid(prev_winid)
    else
      wincmd p
    endif
    nnoremap <buffer> <silent> <Tab> :call neofinder#core#resume_from_editor()<CR>
    return
  endwhile
endfunction

" ---------------------------------------------------------------------------
" Accept the current selection
" ---------------------------------------------------------------------------
function! s:accept(action) abort
  let targets = keys(s:state.selected)
  if empty(targets)
    if s:state.cursor >= 0 && s:state.cursor < len(s:state.filtered)
      let targets = [s:state.filtered[s:state.cursor]]
    endif
  endif

  if empty(targets)
    call s:cleanup()
    return
  endif

  " In browse mode, resolve relative names to full paths
  if s:state.source ==# 'browse'
    let root = get(g:neofinder, '_browse_dir', getcwd())
    let resolved = []
    for t in targets
      " Index results contain '/' so they're relative to root, not browse_dir
      if t =~# '/' && !isdirectory(s:browse_dir . '/' . t)
        call add(resolved, fnamemodify(root . '/' . t, ':p'))
      else
        call add(resolved, fnamemodify(s:browse_dir . '/' . t, ':p'))
      endif
    endfor
    let targets = resolved
  endif

  let source = s:state.source
  let s:browse_dir = ''
  let s:browse_history = []
  call s:cleanup()

  " Dispatch to actions
  call neofinder#actions#execute(source, a:action, targets)
endfunction
