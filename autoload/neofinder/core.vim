" neofinder#core  -- fuzzy matching engine, buffer-based UI, multi-select
"
" Works on Vim 7.4+ (buffer-based), Vim 8+ (popup if available), Neovim.

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
      " Bonus for consecutive matches
      if last_match == si - 1
        let consecutive += 1
        let score += consecutive * 5
      else
        let consecutive = 0
      endif
      " Bonus for match at word boundary
      if si == 0 || str[si - 1] =~# '[/_.\- ]'
        let score += 15
      endif
      let last_match = si
      let pi += 1
    endif
  endfor
  " All pattern chars must match
  if pi < len(pat)
    return -1
  endif
  " Prefer shorter strings (tighter match)
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
  " Sort descending by score
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

  " Create the finder buffer
  call s:create_buffer()
  call s:refilter()
  call s:redraw()

  " Start the input loop
  call s:input_loop()
endfunction

" ---------------------------------------------------------------------------
" Buffer creation -- simple split at the bottom
" ---------------------------------------------------------------------------
function! s:create_buffer() abort
  let height = get(g:neofinder, 'height', 15)

  " Close any previous neofinder buffer
  call s:cleanup()

  botright new
  let s:state.bufnr = bufnr('%')
  execute 'resize ' . (height + 2)

  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
  setlocal nowrap nonumber norelativenumber nospell
  setlocal nocursorline nocursorcolumn
  setlocal filetype=neofinder

  " Highlight groups for this buffer
  call neofinder#theme#set_buffer_highlights()
endfunction

" ---------------------------------------------------------------------------
" Cleanup
" ---------------------------------------------------------------------------
function! s:cleanup() abort
  " Close preview
  call neofinder#preview#close()
  " Wipe finder buffer
  if s:state.bufnr > 0 && bufexists(s:state.bufnr)
    execute 'bwipeout! ' . s:state.bufnr
  endif
  let s:state.bufnr = -1
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

  " Status line
  let backend = neofinder#backend()
  let status = printf('  [%s] %d/%d  |  %s  |  multi:%d',
        \ toupper(s:state.source), matched, total, backend,
        \ len(s:state.selected))
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

  " Apply highlighting to rendered lines
  call s:highlight_lines(cur - start + 3)

  " Update preview
  if get(g:neofinder, 'preview', 1) && s:state.source !=# 'help'
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
  " Prompt
  call matchadd('NeoFinderPrompt', '\%1l')
  " Status
  call matchadd('NeoFinderStatus', '\%2l')
  " Selected items (marked with *)
  call matchadd('NeoFinderSelected', '^\s*>\?\s\+\*.*$')
  " Cursor line
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

    " Handle special keys
    if type(c) == type(0)
      let ch = nr2char(c)
    else
      let ch = c
    endif

    " Escape / Ctrl-C → close
    if c == 27 || c == 3
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

    " Ctrl-H → ssh  (note: 8 is backspace in some terminals, so use Ctrl-H
    " only when source is 'hosts')
    if c == 8 && s:state.source ==# 'hosts'
      call s:accept('ssh')
      return
    endif

    " Backspace (127 or special key)
    if c == 127 || c == "\<BS>"
      if len(s:state.query) > 0
        let s:state.query = s:state.query[:-2]
        call s:refilter()
        call s:redraw()
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
        " Move down after toggle
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

    " Ctrl-D → deselect all
    if c == 4
      let s:state.selected = {}
      call s:redraw()
      continue
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
" Accept the current selection
" ---------------------------------------------------------------------------
" ---------------------------------------------------------------------------
" Public accessor for state (used by preview.vim)
" ---------------------------------------------------------------------------
function! neofinder#core#state() abort
  return s:state
endfunction

function! s:accept(action) abort
  " Gather targets: multi-select or single cursor item
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
