" neofinder#sources  -- data gathering for each source type
"
" Each source returns a flat list of strings to be displayed in the finder.

" ---------------------------------------------------------------------------
" Dispatcher
" ---------------------------------------------------------------------------
function! neofinder#sources#gather(source) abort
  if a:source ==# 'files'
    return s:gather_files()
  elseif a:source ==# 'configs'
    return s:gather_configs()
  elseif a:source ==# 'logs'
    return s:gather_logs()
  elseif a:source ==# 'services'
    return s:gather_services()
  elseif a:source ==# 'journal'
    return s:gather_journal()
  elseif a:source ==# 'hosts'
    return s:gather_hosts()
  elseif a:source ==# 'ansible'
    return s:gather_ansible()
  elseif a:source ==# 'browse'
    return s:gather_browse(get(g:neofinder, '_browse_dir', getcwd()))
  elseif a:source ==# 'scripts'
    return s:gather_scripts()
  elseif a:source ==# 'wordlists'
    return s:gather_wordlists()
  elseif a:source ==# 'exploits'
    return s:gather_exploits()
  elseif a:source ==# 'tags'
    return s:gather_tags()
  elseif a:source ==# 'taggroups'
    return s:gather_taggroups()
  elseif a:source ==# 'buffers'
    return s:gather_buffers()
  elseif a:source ==# 'tabgroups'
    return s:gather_tabgroups()
  elseif a:source ==# 'commands'
    return s:gather_commands()
  elseif a:source ==# 'run'
    return s:gather_run()
  endif
  return []
endfunction

" ---------------------------------------------------------------------------
" files -- general fuzzy finder from cwd
" ---------------------------------------------------------------------------
function! s:gather_files() abort
  let max = get(g:neofinder, 'max_files', 50000)
  let be = neofinder#backend()
  let ignore = neofinder#ignore_flags()

  if be ==# 'rg'
    let cmd = 'rg --files --hidden ' . ignore . ' 2>/dev/null | head -n ' . max
    return s:run_cmd(cmd)
  elseif be ==# 'fd'
    let cmd = 'fd --type f --hidden ' . ignore . ' 2>/dev/null | head -n ' . max
    return s:run_cmd(cmd)
  else
    " Pure Vim fallback (works on Windows without rg/fd)
    return s:glob_files(getcwd(), max)
  endif
endfunction

" ---------------------------------------------------------------------------
" configs -- /etc, ~/.config, and related
" ---------------------------------------------------------------------------
function! s:gather_configs() abort
  let paths = get(g:neofinder, 'config_paths', ['/etc', expand('~/.config')])
  let max = get(g:neofinder, 'max_files', 50000)
  let be = neofinder#backend()

  if be ==# 'glob'
    return s:glob_in_paths(paths, ['*'], max)
  endif

  let results = []
  for p in paths
    if !isdirectory(p) | continue | endif
    if be ==# 'rg'
      let cmd = 'rg --files --hidden ' . shellescape(p) . ' 2>/dev/null | head -n ' . max
    else
      let cmd = 'fd --type f --hidden . ' . shellescape(p) . ' 2>/dev/null | head -n ' . max
    endif
    let results += s:run_cmd(cmd)
  endfor
  return results
endfunction

" ---------------------------------------------------------------------------
" logs -- /var/log
" ---------------------------------------------------------------------------
function! s:gather_logs() abort
  let paths = get(g:neofinder, 'log_paths', ['/var/log'])
  let be = neofinder#backend()

  if be ==# 'glob'
    return s:glob_in_paths(paths, ['*.log', '*.txt', '*'], 5000)
  endif

  let results = []
  for p in paths
    if !isdirectory(p) | continue | endif
    if be ==# 'rg'
      let cmd = 'rg --files ' . shellescape(p) . ' 2>/dev/null | head -n 5000'
    else
      let cmd = 'fd --type f . ' . shellescape(p) . ' 2>/dev/null | head -n 5000'
    endif
    let results += s:run_cmd(cmd)
  endfor
  return results
endfunction

" ---------------------------------------------------------------------------
" services -- systemd unit listing
" ---------------------------------------------------------------------------
function! s:gather_services() abort
  if !executable('systemctl')
    return ['(systemctl not available)']
  endif
  let cmd = 'systemctl list-unit-files --type=service --no-legend --no-pager 2>/dev/null'
  let raw = s:run_cmd(cmd)
  let results = []
  for line in raw
    " Each line: name.service  enabled/disabled/static/masked
    let parts = split(line)
    if len(parts) >= 2
      call add(results, parts[0] . '  [' . parts[1] . ']')
    elseif len(parts) == 1
      call add(results, parts[0])
    endif
  endfor
  return results
endfunction

" ---------------------------------------------------------------------------
" journal -- journalctl recent entries
" ---------------------------------------------------------------------------
function! s:gather_journal() abort
  if !executable('journalctl')
    return ['(journalctl not available)']
  endif
  let cmd = 'journalctl --no-pager -n 500 --output=short 2>/dev/null'
  return s:run_cmd(cmd)
endfunction

" ---------------------------------------------------------------------------
" hosts -- SSH hosts from ~/.ssh/config and known_hosts
" ---------------------------------------------------------------------------
function! s:gather_hosts() abort
  let results = []

  " Parse ~/.ssh/config
  let ssh_config = get(g:neofinder, 'ssh_config', expand('~/.ssh/config'))
  if filereadable(ssh_config)
    let lines = readfile(ssh_config)
    for line in lines
      let m = matchstr(line, '^\s*Host\s\+\zs.\+')
      if m !=# '' && m !~# '[*?]'
        " May have multiple hosts on one line
        for h in split(m)
          if index(results, h) < 0
            call add(results, h)
          endif
        endfor
      endif
    endfor
  endif

  " Parse known_hosts (extract hostnames/IPs)
  let known = get(g:neofinder, 'known_hosts', expand('~/.ssh/known_hosts'))
  if filereadable(known)
    let lines = readfile(known)
    for line in lines
      if line =~# '^#' || line =~# '^\s*$'
        continue
      endif
      " First field is comma-separated host list (may be hashed)
      let hosts_field = split(line)[0]
      if hosts_field =~# '^|'
        continue  " hashed entry, skip
      endif
      for h in split(hosts_field, ',')
        " Strip port brackets like [host]:port
        let h = substitute(h, '^\[\(.\{-}\)\]:\d\+$', '\1', '')
        if index(results, h) < 0
          call add(results, h)
        endif
      endfor
    endfor
  endif

  return results
endfunction

" ---------------------------------------------------------------------------
" ansible -- playbooks, inventories, roles
" ---------------------------------------------------------------------------
function! s:gather_ansible() abort
  let paths = get(g:neofinder, 'ansible_paths',
        \ ['/etc/ansible', expand('~/ansible'), expand('~/playbooks'), '.'])
  let exts = ['*.yml', '*.yaml', '*.ini', '*.cfg', '*.j2', '*.json']

  if neofinder#backend() ==# 'glob'
    return s:glob_in_paths(paths, exts, 50000)
  endif

  let results = []
  for p in paths
    if !isdirectory(p) | continue | endif
    if neofinder#backend() ==# 'rg'
      let cmd = 'rg --files --hidden -g "*.yml" -g "*.yaml" -g "*.ini" -g "*.cfg" -g "*.j2" -g "*.json" '
            \ . shellescape(p) . ' 2>/dev/null'
    else
      let cmd = 'fd -e yml -e yaml -e ini -e cfg -e j2 -e json --type f . '
            \ . shellescape(p) . ' 2>/dev/null'
    endif
    let results += s:run_cmd(cmd)
  endfor

  return results
endfunction

" ---------------------------------------------------------------------------
" browse -- directory browser with cache
" ---------------------------------------------------------------------------
let s:browse_cache = {}

function! s:gather_browse(dir) abort
  let dir = fnamemodify(a:dir, ':p')
  if !isdirectory(dir)
    return ['(not a directory)']
  endif

  " Return cached if available
  if has_key(s:browse_cache, dir)
    return s:browse_cache[dir]
  endif

  let ignores = get(g:neofinder, 'ignore', [])
  let results = []

  " Directories first
  for d in glob(dir . '*/', 0, 1) + glob(dir . '.*/', 0, 1)
    let name = fnamemodify(d, ':h:t')
    if name ==# '.' || name ==# '..' | continue | endif
    let skip = 0
    for ign in ignores
      if name ==# ign || name ==# fnamemodify(ign, ':t')
        let skip = 1 | break
      endif
    endfor
    if !skip | call add(results, name . '/') | endif
  endfor
  call sort(results)

  " Then files
  let file_list = []
  for f in glob(dir . '*', 0, 1) + glob(dir . '.*', 0, 1)
    if isdirectory(f) | continue | endif
    let name = fnamemodify(f, ':t')
    if name ==# '.' || name ==# '..' | continue | endif
    call add(file_list, name)
  endfor
  call sort(file_list)
  let results += file_list

  " Cache it
  let s:browse_cache[dir] = results
  return results
endfunction

" Public: get browse items (cached)
function! neofinder#sources#gather_browse(dir) abort
  return s:gather_browse(a:dir)
endfunction

" Public: invalidate cache for a dir (or all)
function! neofinder#sources#invalidate_cache(...) abort
  if a:0
    let dir = fnamemodify(a:1, ':p')
    if has_key(s:browse_cache, dir)
      call remove(s:browse_cache, dir)
    endif
  else
    let s:browse_cache = {}
  endif
endfunction

" ---------------------------------------------------------------------------
" scripts -- personal scripts in ~/bin, /usr/local/bin, ~/scripts, etc.
" ---------------------------------------------------------------------------
function! s:gather_scripts() abort
  let paths = get(g:neofinder, 'script_paths', [
        \ expand('~/bin'), expand('~/scripts'), expand('~/.local/bin'),
        \ '/usr/local/bin', '/usr/local/sbin'])
  if neofinder#backend() ==# 'glob'
    return s:glob_in_paths(paths, ['*'], 5000)
  endif
  let results = []
  for p in paths
    if !isdirectory(p) | continue | endif
    if neofinder#backend() ==# 'rg'
      let cmd = 'rg --files ' . shellescape(p) . ' 2>/dev/null | head -n 5000'
    else
      let cmd = 'fd --type f . ' . shellescape(p) . ' 2>/dev/null | head -n 5000'
    endif
    let results += s:run_cmd(cmd)
  endfor
  return results
endfunction

" ---------------------------------------------------------------------------
" wordlists -- /usr/share/wordlists/ and custom paths (pentest)
" ---------------------------------------------------------------------------
function! s:gather_wordlists() abort
  let paths = get(g:neofinder, 'wordlist_paths', [
        \ '/usr/share/wordlists', '/usr/share/seclists',
        \ expand('~/wordlists')])
  if neofinder#backend() ==# 'glob'
    return s:glob_in_paths(paths, ['*.txt', '*.lst', '*.dic'], 10000)
  endif
  let results = []
  for p in paths
    if !isdirectory(p) | continue | endif
    if neofinder#backend() ==# 'rg'
      let cmd = 'rg --files -g "*.txt" -g "*.lst" -g "*.dic" ' . shellescape(p) . ' 2>/dev/null | head -n 10000'
    else
      let cmd = 'fd -e txt -e lst -e dic --type f . ' . shellescape(p) . ' 2>/dev/null | head -n 10000'
    endif
    let results += s:run_cmd(cmd)
  endfor
  return results
endfunction

" ---------------------------------------------------------------------------
" exploits -- searchsploit DB, metasploit modules, custom exploit dirs
" ---------------------------------------------------------------------------
function! s:gather_exploits() abort
  let paths = get(g:neofinder, 'exploit_paths', [
        \ '/usr/share/exploitdb/exploits',
        \ '/usr/share/metasploit-framework/modules',
        \ expand('~/exploits'), expand('~/payloads')])
  if neofinder#backend() ==# 'glob'
    return s:glob_in_paths(paths, ['*'], 10000)
  endif
  let results = []
  for p in paths
    if !isdirectory(p) | continue | endif
    if neofinder#backend() ==# 'rg'
      let cmd = 'rg --files ' . shellescape(p) . ' 2>/dev/null | head -n 10000'
    else
      let cmd = 'fd --type f . ' . shellescape(p) . ' 2>/dev/null | head -n 10000'
    endif
    let results += s:run_cmd(cmd)
  endfor
  return results
endfunction

" ---------------------------------------------------------------------------
" tags -- bookmarked files
" ---------------------------------------------------------------------------
function! s:gather_tags() abort
  return neofinder#tags#list()
endfunction

" ---------------------------------------------------------------------------
" taggroups -- tag group names
" ---------------------------------------------------------------------------
function! s:gather_taggroups() abort
  return neofinder#tags#list_groups()
endfunction

" ---------------------------------------------------------------------------
" buffers -- open listed buffers
" ---------------------------------------------------------------------------
function! s:gather_buffers() abort
  return neofinder#buffers#list()
endfunction

" ---------------------------------------------------------------------------
" tabgroups -- named tab groups
" ---------------------------------------------------------------------------
function! s:gather_tabgroups() abort
  return neofinder#buffers#list_groups()
endfunction

" ---------------------------------------------------------------------------
" commands -- .py/.toml files in commands dir + create new
" ---------------------------------------------------------------------------
function! s:gather_commands() abort
  let results = ['[+] New command']
  let dirs = [neofinder#python#commands_dir(), expand('~/.neofinder/python')]
  for dir in dirs
    if !isdirectory(dir)
      continue
    endif
    for f in glob(dir . '/*.py', 0, 1)
      let name = fnamemodify(f, ':t')
      let toml = substitute(f, '\.py$', '.toml', '')
      let tag = filereadable(toml) ? ' [ok]' : ' [no handler]'
      call add(results, name . tag . '  ' . f)
    endfor
  endfor
  return results
endfunction

" ---------------------------------------------------------------------------
" run -- command names for execution
" ---------------------------------------------------------------------------
function! s:gather_run() abort
  return neofinder#python#list_detailed()
endfunction

" ---------------------------------------------------------------------------
" Helper: run shell command, return list of lines
" ---------------------------------------------------------------------------
function! s:run_cmd(cmd) abort
  let output = system(a:cmd)
  if v:shell_error && output ==# ''
    return []
  endif
  return split(output, "\n")
endfunction

" ---------------------------------------------------------------------------
" Helper: pure Vim glob file finder (works everywhere, no external tools)
" ---------------------------------------------------------------------------
function! s:glob_files(dir, max) abort
  let ignores = get(g:neofinder, 'ignore', [])
  let cwd = substitute(fnamemodify(a:dir, ':p'), '\\', '/', 'g')
  if cwd !~# '/$'
    let cwd .= '/'
  endif

  let all = glob(cwd . '**/*', 0, 1)
  let results = []

  for f in all
    if isdirectory(f)
      continue
    endif
    let fslash = substitute(f, '\\', '/', 'g')
    " Check ignore
    let skip = 0
    for ign in ignores
      if stridx(fslash, ign) >= 0
        let skip = 1
        break
      endif
    endfor
    if skip
      continue
    endif
    " Relative path
    let rel = fslash[len(cwd):]
    call add(results, rel)
    if len(results) >= a:max
      break
    endif
  endfor
  return results
endfunction
