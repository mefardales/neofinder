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

function! s:filter_items(items, query) abort
  if a:query ==# ''
    return copy(a:items)
  endif
  let scored = []
  for item in a:items
    let sc = s:fuzzy_score(a:query, item)
    if sc >= 0
      call add(scored, [sc, item])
    endif
  endfor
  call sort(scored, {a, b -> b[0] - a[0]})
  return map(scored, 'v:val[1]')
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

  call neofinder#theme#apply()

  call s:create_buffer()
  call s:refilter()
  call s:redraw()

  call s:input_loop()
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
  setlocal nocursorline nocursorcolumn
  setlocal filetype=neofinder

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

  " Status line -- show navigation hints
  let backend = neofinder#backend()
  let nav_hint = !empty(s:nav_stack) ? '  [BS] back' : ''
  let status = printf('  [%s] %d/%d  |  %s  |  multi:%d%s',
        \ toupper(s:state.source), matched, total, backend,
        \ len(s:state.selected), nav_hint)
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
      call neofinder#preview#show(filtered[cur], s:state.source)
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

    " Enter → accept
    if c == 13
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

    " Ctrl-T → tail -f
    if c == 20
      call s:accept('tail')
      return
    endif

    " Ctrl-R → systemctl restart
    if c == 18
      call s:accept('restart')
      return
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

    " Tab → toggle multi-select on current item
    if c == 9
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

    " Ctrl-A → select all visible
    if c == 1
      for item in s:state.filtered
        let s:state.selected[item] = 1
      endfor
      call s:redraw()
      continue
    endif

    " Ctrl-D → delete buffer (buffers source) or deselect all
    if c == 4
      if s:state.source ==# 'buffers' && s:state.cursor < len(s:state.filtered)
        let item = s:state.filtered[s:state.cursor]
        let nr = neofinder#buffers#extract_bufnr(item)
        if nr > 0 && bufexists(nr)
          execute 'bwipeout ' . nr
          let s:state.items = neofinder#sources#gather('buffers')
          call s:refilter()
        endif
      else
        let s:state.selected = {}
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

    " F1 → open config panel
    if ch ==# "\<F1>"
      call s:cleanup()
      call neofinder#config#open()
      " After config closes, return to palette
      let s:nav_stack = []
      call neofinder#palette('')
      return
    endif

    " Printable character → add to query
    if ch =~# '[ -~]'
      let s:state.query .= ch
      call s:refilter()
      call s:redraw()
      continue
    endif
  endwhile
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

  let source = s:state.source
  call s:cleanup()

  " Dispatch to actions
  call neofinder#actions#execute(source, a:action, targets)
endfunction
