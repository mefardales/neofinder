" neofinder#actions  -- contextual actions dispatched from the finder
"
" Called by core.vim after the user accepts a selection.

" ---------------------------------------------------------------------------
" execute({source}, {action}, {targets})
" ---------------------------------------------------------------------------
function! neofinder#actions#execute(source, action, targets) abort
  if empty(a:targets)
    return
  endif

  " Route by action type
  if a:action ==# 'edit'
    call s:action_edit(a:source, a:targets)
  elseif a:action ==# 'vsplit'
    call s:action_vsplit(a:targets)
  elseif a:action ==# 'split'
    call s:action_split(a:targets)
  elseif a:action ==# 'sudo'
    call s:action_sudo(a:targets)
  elseif a:action ==# 'tail'
    call s:action_tail(a:targets)
  elseif a:action ==# 'restart'
    call s:action_systemctl('restart', a:targets)
  elseif a:action ==# 'ssh'
    call s:action_ssh(a:targets)
  endif
endfunction

" ---------------------------------------------------------------------------
" edit -- default open, context-aware
" ---------------------------------------------------------------------------
function! s:action_edit(source, targets) abort
  if a:source ==# 'hosts'
    call s:action_ssh(a:targets)
    return
  endif

  if a:source ==# 'services'
    " Show status of the first selected service
    let unit = s:extract_unit(a:targets[0])
    call s:run_terminal_cmd('systemctl status ' . shellescape(unit))
    return
  endif

  if a:source ==# 'journal'
    " Journal lines are just text; do nothing special
    return
  endif

  " Default: open files
  for target in a:targets
    if filereadable(target)
      execute 'edit ' . fnameescape(target)
    elseif isdirectory(target)
      execute 'edit ' . fnameescape(target)
    endif
  endfor
endfunction

" ---------------------------------------------------------------------------
" vsplit / split
" ---------------------------------------------------------------------------
function! s:action_vsplit(targets) abort
  for target in a:targets
    execute 'vsplit ' . fnameescape(target)
  endfor
endfunction

function! s:action_split(targets) abort
  for target in a:targets
    execute 'split ' . fnameescape(target)
  endfor
endfunction

" ---------------------------------------------------------------------------
" sudoedit
" ---------------------------------------------------------------------------
function! s:action_sudo(targets) abort
  for target in a:targets
    if has('nvim')
      execute 'terminal sudoedit ' . shellescape(target)
    else
      " Vim 8: use :terminal or fall back to :! for Vim 7
      if exists(':terminal')
        execute 'terminal ++close sudoedit ' . shellescape(target)
      else
        execute '!sudoedit ' . shellescape(target)
      endif
    endif
  endfor
endfunction

" ---------------------------------------------------------------------------
" tail -f
" ---------------------------------------------------------------------------
function! s:action_tail(targets) abort
  let files = join(map(copy(a:targets), 'shellescape(v:val)'), ' ')
  let cmd = 'tail -f ' . files
  call s:run_terminal_cmd(cmd)
endfunction

" ---------------------------------------------------------------------------
" systemctl actions
" ---------------------------------------------------------------------------
function! s:action_systemctl(verb, targets) abort
  for target in a:targets
    let unit = s:extract_unit(target)
    let cmd = 'sudo systemctl ' . a:verb . ' ' . shellescape(unit)
    call s:run_terminal_cmd(cmd)
  endfor
endfunction

" ---------------------------------------------------------------------------
" ssh
" ---------------------------------------------------------------------------
function! s:action_ssh(targets) abort
  if empty(a:targets)
    return
  endif
  let host = a:targets[0]
  let cmd = 'ssh ' . shellescape(host)
  call s:run_terminal_cmd(cmd)
endfunction

" ---------------------------------------------------------------------------
" Helpers
" ---------------------------------------------------------------------------

" Extract unit name from "sshd.service  [enabled]" format
function! s:extract_unit(line) abort
  return split(a:line)[0]
endfunction

" Run a command in a terminal buffer (Vim 8+ / Neovim)
function! s:run_terminal_cmd(cmd) abort
  if has('nvim')
    execute 'terminal ' . a:cmd
    startinsert
  elseif exists(':terminal')
    execute 'terminal ++close ' . a:cmd
  else
    execute '!' . a:cmd
  endif
endfunction
