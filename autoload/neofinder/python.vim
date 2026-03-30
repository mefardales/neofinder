" neofinder#python  -- Command system based on .py files
"
" Every command is a .py file. No inline code.
"
"   Built-in:  autoload/neofinder/commands/*.py   (shipped with plugin)
"   User:      ~/.neofinder/python/*.py           (your own)
"
" File format:
"   # desc: what this command does
"   nf.sh_output("df -h")
"
" The filename becomes the command name:
"   disk_usage.py  ->  DiskUsage
"   git_log.py     ->  GitLog

" ---------------------------------------------------------------------------
" Registry:  { 'Name': { 'file': '/path/to.py', 'desc': '...' } }
" ---------------------------------------------------------------------------
let s:registry = {}

" ---------------------------------------------------------------------------
" Python3 check
" ---------------------------------------------------------------------------
let s:has_py3 = -1
function! neofinder#python#has_python3() abort
  if s:has_py3 < 0
    let s:has_py3 = has('python3') ? 1 : 0
  endif
  return s:has_py3
endfunction

" ---------------------------------------------------------------------------
" Register a .py file as a command
" ---------------------------------------------------------------------------
function! s:register_file(name, path) abort
  if !filereadable(a:path)
    return
  endif
  let desc = s:read_desc(a:path)
  let s:registry[a:name] = {'file': a:path, 'desc': desc}
endfunction

" Read description: first try .json handler, then '# desc:' from .py
function! s:read_desc(path) abort
  " Try .json handler first
  let json_path = substitute(a:path, '\.py$', '.json', '')
  if filereadable(json_path)
    try
      let raw = join(readfile(json_path), '')
      let data = json_decode(raw)
      if type(data) == type({}) && has_key(data, 'desc')
        return data.desc
      endif
    catch
    endtry
  endif
  " Fallback: # desc: in .py
  let lines = readfile(a:path, '', 5)
  for line in lines
    let m = matchstr(line, '^#\s*desc:\s*\zs.*')
    if m !=# ''
      return m
    endif
  endfor
  return fnamemodify(a:path, ':t')
endfunction

" Convert filename to PascalCase command name
"   git_log.py  ->  GitLog
"   hello.py    ->  Hello
function! s:file_to_name(path) abort
  let base = fnamemodify(a:path, ':t:r')
  let parts = split(base, '_')
  return join(map(parts, 'toupper(v:val[0]) . v:val[1:]'), '')
endfunction

" ---------------------------------------------------------------------------
" Scan a directory and register all .py files
" ---------------------------------------------------------------------------
function! s:scan_dir(dir) abort
  if !isdirectory(a:dir)
    return
  endif
  for f in glob(a:dir . '/*.py', 0, 1)
    let name = s:file_to_name(f)
    if !has_key(s:registry, name)
      call s:register_file(name, f)
    endif
  endfor
endfunction

" Debug: show what was loaded (call with :call neofinder#python#debug())
function! neofinder#python#debug() abort
  echo 'script_dir: ' . s:script_dir
  echo 'builtin_dir: ' . s:builtin_dir
  echo 'exists: ' . isdirectory(s:builtin_dir)
  echo 'registry: ' . string(keys(s:registry))
endfunction

" ---------------------------------------------------------------------------
" Execute a command
" ---------------------------------------------------------------------------
function! neofinder#python#exec(name) abort
  if !has_key(s:registry, a:name)
    echohl ErrorMsg | echo '[NeoFinder] Unknown command: ' . a:name | echohl None
    return
  endif
  if !neofinder#python#has_python3()
    echohl ErrorMsg
    echo '[NeoFinder] python3 required. Check :echo has("python3")'
    echohl None
    return
  endif

  call s:ensure_runtime()

  let pyfile = substitute(s:registry[a:name].file, '\\', '/', 'g')
  try
    execute 'python3 _run_command("' . escape(pyfile, '"') . '")'
  catch
    echohl ErrorMsg | echo '[NeoFinder] ' . v:exception | echohl None
  endtry
endfunction

" ---------------------------------------------------------------------------
" Runtime loader (loads nf object once)
" ---------------------------------------------------------------------------
let s:runtime_loaded = 0
let s:script_dir = expand('<sfile>:p:h')
let s:runtime_path = s:script_dir . '/runtime.py'
let s:builtin_dir = s:script_dir . '/commands'

function! s:ensure_runtime() abort
  if !s:runtime_loaded
    let rtpath = substitute(s:runtime_path, '\\', '/', 'g')
    execute 'py3file ' . fnameescape(rtpath)
    let s:runtime_loaded = 1
  endif
endfunction

" ---------------------------------------------------------------------------
" Query / list
" ---------------------------------------------------------------------------
function! neofinder#python#list() abort
  return keys(s:registry)
endfunction

function! neofinder#python#list_detailed() abort
  let result = []
  for [name, entry] in items(s:registry)
    call add(result, printf('  %-20s %s', name, entry.desc))
  endfor
  return sort(result)
endfunction

function! neofinder#python#show_list() abort
  if empty(s:registry)
    echohl NeoFinderPrompt
    echo '  No commands. Put .py files in ~/.neofinder/python/'
    echohl None
    return
  endif
  echohl NeoFinderPrompt
  echo '  NeoFinder Commands'
  echo '  ' . repeat('=', 50)
  echohl None
  for line in neofinder#python#list_detailed()
    echo line
  endfor
  if !neofinder#python#has_python3()
    echohl WarningMsg | echo '  Note: python3 not available' | echohl None
  endif
endfunction

function! neofinder#python#complete(lead, line, pos) abort
  return filter(keys(s:registry), 'v:val =~# "^" . a:lead')
endfunction

function! neofinder#python#bind(name, key) abort
  if !has_key(s:registry, a:name)
    echohl ErrorMsg | echo '[NeoFinder] Unknown: ' . a:name | echohl None
    return
  endif
  execute printf('nnoremap <silent> %s :NeoPythonExec %s<CR>', a:key, a:name)
endfunction

function! neofinder#python#unregister(name) abort
  if has_key(s:registry, a:name)
    call remove(s:registry, a:name)
  endif
endfunction

" ---------------------------------------------------------------------------
" Autoload: scan built-in commands dir + user dir
" ---------------------------------------------------------------------------
let s:autoloaded = 0
function! neofinder#python#autoload() abort
  if s:autoloaded
    return
  endif
  let s:autoloaded = 1

  " 1) Built-in commands (shipped with plugin)
  call s:scan_dir(s:builtin_dir)

  " 2) User commands
  call s:scan_dir(expand('~/.neofinder/python'))
endfunction
