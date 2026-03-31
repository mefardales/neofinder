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

" Read description from .toml handler or '# desc:' from .py
function! s:read_desc(path) abort
  " Try .toml handler first
  let toml_path = substitute(a:path, '\.py$', '.toml', '')
  if filereadable(toml_path)
    for line in readfile(toml_path, '', 10)
      let m = matchstr(line, '^desc\s*=\s*"\zs[^"]*')
      if m !=# ''
        return m
      endif
    endfor
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

" Public accessor for commands directory
function! neofinder#python#commands_dir() abort
  return s:builtin_dir
endfunction

" Public accessor for user commands directory
function! neofinder#python#user_dir() abort
  return get(g:neofinder, 'commands_dir', expand('~/.neofinder/python'))
endfunction

" Create a new command from template
function! neofinder#python#create(name) abort
  let dir = expand('~/.neofinder/python')
  if !isdirectory(dir)
    call mkdir(dir, 'p', 0700)
  endif

  " Convert name to snake_case filename
  let filename = tolower(substitute(a:name, '\([A-Z]\)', '_\1', 'g'))
  let filename = substitute(filename, '^_', '', '')
  let py_path = dir . '/' . filename . '.py'
  let toml_path = dir . '/' . filename . '.toml'

  if filereadable(py_path)
    echohl ErrorMsg | echo 'Already exists: ' . py_path | echohl None
    return ''
  endif

  " Write .toml handler
  let toml_lines = [
        \ '# ══════════════════════════════════════════════════════════',
        \ '# ' . a:name . ' -- Command Handler',
        \ '# ══════════════════════════════════════════════════════════',
        \ '',
        \ 'name = "' . a:name . '"',
        \ 'desc = "TODO: describe this command"',
        \ '',
        \ '# ── Dependencies ──────────────────────────────────────────',
        \ '# What this command uses from the runtime:',
        \ '#   "input"  = asks user for variables (see [in])',
        \ '#   "output" = writes to output buffer (STDOUT)',
        \ '#   "shell"  = runs shell commands (nf.sh)',
        \ '#   "buffer" = reads/writes current buffer (nf.buf)',
        \ '#   "tags"   = accesses tag groups (nf.tags)',
        \ 'deps = ["output"]',
        \ '',
        \ '# ── Input Variables ────────────────────────────────────────',
        \ '# Each key becomes a variable injected into your .py',
        \ '# The value is the prompt shown to the user',
        \ '[in]',
        \ '# host = "Host/IP: "',
        \ '# port = "Port (8080): "',
        \ '',
        \ '# ── Output ────────────────────────────────────────────────',
        \ '# Title for the output buffer. Use ${var} to interpolate.',
        \ 'out = "[' . a:name . ']"',
        \ '',
        \ '# ── Pipe ──────────────────────────────────────────────────',
        \ '# Load current buffer content into STDIN before execution',
        \ '# pipe = "buffer"    # STDIN.text / STDIN.lines',
        \ ]
  call writefile(toml_lines, toml_path)

  " Write .py template with full reference
  let py_lines = [
        \ '# ── ' . a:name . ' ─────────────────────────────────────',
        \ '#',
        \ '# STANDARD I/O (injected by handler):',
        \ '#   STDIN.text / STDIN.lines    piped input (from buffer or "in")',
        \ '#   STDIN.varname               variables from handler "in"',
        \ '#   STDOUT.print("line")        collect output (auto-flush to buffer)',
        \ '#   STDOUT.write(["a","b"])     collect multiple lines',
        \ '#   STDERR.print("error")       collect errors (auto-shown after)',
        \ '#',
        \ '# CONTEXT:',
        \ '#   nf.file / nf.dir / nf.line / nf.filetype / nf.theme',
        \ '#',
        \ '# BUFFER (nf.buf):',
        \ '#   .lines .text .name .line .line_number .selection',
        \ '#   .write(x) .append(x) .insert(x,n) .clear() [i] [i]=x',
        \ '#',
        \ '# SHELL:',
        \ '#   stdout, stderr, rc = nf.sh("cmd")',
        \ '#   nf.sh_output("cmd")         run & show in output buffer',
        \ '#   nf.sh_lines("cmd")          returns list of lines',
        \ '#',
        \ '# INPUT:',
        \ '#   nf.input("prompt")          ask user for text',
        \ '#   nf.confirm("sure?")         yes/no dialog',
        \ '#   nf.select(["a","b"])        pick from list',
        \ '#',
        \ '# TAGS:',
        \ '#   nf.tags.groups() .files(group) .add(path,group) .remove(path)',
        \ '#',
        \ '# FILES:',
        \ '#   nf.open(p) .vsplit(p) .split(p) .scratch(lines,title) .buffers()',
        \ '#',
        \ '# MESSAGES:',
        \ '#   nf.echo(x) .warn(x) .error(x)',
        \ '# ────────────────────────────────────────────────────────',
        \ '',
        \ 'STDOUT.print("' . a:name . '")',
        \ 'STDOUT.print("=" * 40)',
        \ 'STDOUT.print("")',
        \ '',
        \ '# Your code here',
        \ ]
  call writefile(py_lines, py_path)

  " Register it
  call s:register_file(a:name, py_path)

  return py_path
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
