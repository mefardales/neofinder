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

  " Palette dispatch -- run the selected palette action
  if a:source ==# 'palette'
    call neofinder#palette_dispatch(a:targets[0])
    return
  endif

  " Route by action type
  if a:action ==# 'edit'
    call s:action_edit(a:source, a:targets)
  elseif a:action ==# 'vsplit'
    call s:action_vsplit(a:source, a:targets)
  elseif a:action ==# 'split'
    call s:action_split(a:source, a:targets)
  elseif a:action ==# 'sudo'
    call s:action_sudo(a:targets)
  elseif a:action ==# 'tail'
    call s:action_tail(a:targets)
  elseif a:action ==# 'restart'
    call s:action_systemctl('restart', a:targets)
  elseif a:action ==# 'ssh'
    call s:action_ssh(a:targets)
  elseif a:action ==# 'delete'
    call s:action_delete_buffer(a:targets)
  elseif a:action ==# 'terminal'
    call neofinder#buffers#open_terminal()
  endif
endfunction

" ---------------------------------------------------------------------------
" edit -- default open, context-aware
" ---------------------------------------------------------------------------
function! s:action_edit(source, targets) abort
  if a:source ==# 'hosts'
    call s:action_host_info(a:targets)
    return
  endif

  if a:source ==# 'services'
    let unit = s:extract_unit(a:targets[0])
    call s:run_terminal_cmd('systemctl status ' . shellescape(unit))
    return
  endif

  if a:source ==# 'journal'
    return
  endif

  if a:source ==# 'buffers'
    let nr = neofinder#buffers#extract_bufnr(a:targets[0])
    if nr > 0 && bufexists(nr)
      execute 'buffer ' . nr
    endif
    return
  endif

  if a:source ==# 'tabgroups'
    let name = neofinder#buffers#extract_group_name(a:targets[0])
    if name !=# ''
      call neofinder#buffers#switch_to_group(name)
    endif
    return
  endif

  if a:source ==# 'taggroups'
    let name = neofinder#tags#extract_group_name(a:targets[0])
    if name !=# ''
      let items = neofinder#tags#list_by_group(name)
      call neofinder#core#run_from_palette('tags', items, '')
    endif
    return
  endif

  if a:source ==# 'run'
    let name = matchstr(a:targets[0], '^\s*\zs\S\+')
    if name !=# ''
      call neofinder#python#exec(name)
    endif
    return
  endif

  if a:source ==# 'commands'
    let line = a:targets[0]
    if line =~# '^\[+\]'
      " Create new command
      let name = input('Command name (PascalCase): ')
      redraw
      if name !=# ''
        let path = neofinder#python#create(name)
        if path !=# ''
          " Open both files for editing
          let json_path = substitute(path, '\.py$', '.json', '')
          execute 'edit ' . fnameescape(json_path)
          execute 'vsplit ' . fnameescape(path)
          echohl NeoFinderPrompt
          echo '  Created: ' . fnamemodify(path, ':t') . ' + .json'
          echohl None
        endif
      endif
    else
      " Edit existing: extract path after the last space-space
      let path = matchstr(line, '\S\+\.py\s*$')
      " Also try to get the full path from after the tag
      let path = matchstr(line, '\]\s\+\zs\S.*$')
      if path !=# '' && filereadable(path)
        let json_path = substitute(path, '\.py$', '.json', '')
        if filereadable(json_path)
          execute 'edit ' . fnameescape(json_path)
          execute 'vsplit ' . fnameescape(path)
        else
          execute 'edit ' . fnameescape(path)
        endif
      endif
    endif
    return
  endif

  " Default: open files
  let save_hidden = &hidden
  set hidden
  for target in a:targets
    if filereadable(target) || isdirectory(target)
      execute 'edit ' . fnameescape(target)
    endif
  endfor
  let &hidden = save_hidden
endfunction

" ---------------------------------------------------------------------------
" vsplit / split
" ---------------------------------------------------------------------------
function! s:action_vsplit(source, targets) abort
  for target in a:targets
    if a:source ==# 'buffers'
      let nr = neofinder#buffers#extract_bufnr(target)
      if nr > 0 && bufexists(nr)
        execute 'vertical sbuffer ' . nr
      endif
    else
      execute 'vsplit ' . fnameescape(target)
    endif
  endfor
endfunction

function! s:action_split(source, targets) abort
  for target in a:targets
    if a:source ==# 'buffers'
      let nr = neofinder#buffers#extract_bufnr(target)
      if nr > 0 && bufexists(nr)
        execute 'sbuffer ' . nr
      endif
    else
      execute 'split ' . fnameescape(target)
    endif
  endfor
endfunction

" ---------------------------------------------------------------------------
" delete buffer (wipeout)
" ---------------------------------------------------------------------------
function! s:action_delete_buffer(targets) abort
  for target in a:targets
    let nr = neofinder#buffers#extract_bufnr(target)
    if nr > 0 && bufexists(nr)
      execute 'bwipeout ' . nr
    endif
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
" host_info -- Enter on a host: open ssh_config at the Host entry
" ---------------------------------------------------------------------------
function! s:action_host_info(targets) abort
  if empty(a:targets)
    return
  endif
  let host = a:targets[0]
  let ssh_config = get(g:neofinder, 'ssh_config', expand('~/.ssh/config'))

  " Try to open ssh_config and jump to the Host entry
  if filereadable(ssh_config)
    let save_hidden = &hidden
    set hidden
    execute 'edit ' . fnameescape(ssh_config)
    let &hidden = save_hidden
    " Search for the Host line
    call cursor(1, 1)
    let pattern = '^\s*Host\s\+.*\<' . escape(host, '.*[]~\') . '\>'
    let found = search(pattern, 'cw')
    if found > 0
      normal! zz
    endif
    echohl NeoFinderPrompt
    echo '  [' . host . ']  Ctrl-H to SSH connect  |  Editing ssh_config'
    echohl None
  else
    " No ssh_config, try to connect directly
    echohl NeoFinderPrompt
    echo '  Connecting to ' . host . '...'
    echohl None
    call s:action_ssh(a:targets)
  endif
endfunction

" ---------------------------------------------------------------------------
" ssh
" ---------------------------------------------------------------------------
function! s:action_ssh(targets) abort
  if empty(a:targets)
    return
  endif
  let host = a:targets[0]

  if !executable('ssh')
    echohl ErrorMsg
    echo '[NeoFinder] ssh not found in PATH. Install OpenSSH to connect.'
    echohl None
    return
  endif

  echohl NeoFinderPrompt
  echo '  Connecting to ' . host . '...'
  echohl None

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
