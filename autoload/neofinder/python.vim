" neofinder#python  -- Custom Python Commands system
"
" Lets users register and execute Python3 code as named NeoFinder commands.
" Requires Vim/Neovim compiled with +python3.  Degrades gracefully if
" python3 is not available.
"
" Usage:
"   call neofinder#python#register('MyBackup', '
"       import os
"       os.system("cp -r /etc/nginx ~/backup/")
"       print("Done!")
"   ')
"
"   :NeoPythonExec MyBackup
"   :NeoPythonList
"   :NeoPythonBind MyBackup <leader>b
"
"   " Or from a file:
"   call neofinder#python#register_file('Deploy', '~/scripts/deploy.py')

" ---------------------------------------------------------------------------
" Registry:  { 'CommandName': { 'code': '...', 'file': '', 'desc': '' } }
" ---------------------------------------------------------------------------
let s:registry = {}

" ---------------------------------------------------------------------------
" has_python3() -- check once, cache result
" ---------------------------------------------------------------------------
let s:has_py3 = -1
function! neofinder#python#has_python3() abort
  if s:has_py3 < 0
    let s:has_py3 = has('python3') ? 1 : 0
  endif
  return s:has_py3
endfunction

" ---------------------------------------------------------------------------
" register({name}, {python_code} [, {description}])
"   Register an inline Python command.
" ---------------------------------------------------------------------------
function! neofinder#python#register(name, code, ...) abort
  if !neofinder#python#has_python3()
    echohl WarningMsg
    echo '[NeoFinder] python3 not available -- cannot register Python command: ' . a:name
    echohl None
    return 0
  endif
  let desc = a:0 ? a:1 : 'Custom Python command'
  let s:registry[a:name] = {'code': a:code, 'file': '', 'desc': desc}
  return 1
endfunction

" ---------------------------------------------------------------------------
" register_file({name}, {path} [, {description}])
"   Register a Python command that sources a .py file.
" ---------------------------------------------------------------------------
function! neofinder#python#register_file(name, path, ...) abort
  if !neofinder#python#has_python3()
    echohl WarningMsg
    echo '[NeoFinder] python3 not available -- cannot register Python command: ' . a:name
    echohl None
    return 0
  endif
  let fpath = expand(a:path)
  if !filereadable(fpath)
    echohl ErrorMsg
    echo '[NeoFinder] File not found: ' . fpath
    echohl None
    return 0
  endif
  let desc = a:0 ? a:1 : 'Python file: ' . fnamemodify(fpath, ':t')
  let s:registry[a:name] = {'code': '', 'file': fpath, 'desc': desc}
  return 1
endfunction

" ---------------------------------------------------------------------------
" exec({name})
"   Execute a registered Python command by name.
" ---------------------------------------------------------------------------
function! neofinder#python#exec(name) abort
  if !neofinder#python#has_python3()
    echohl ErrorMsg
    echo '[NeoFinder] python3 is not available in this Vim build.'
    echohl None
    return
  endif

  if !has_key(s:registry, a:name)
    echohl ErrorMsg
    echo '[NeoFinder] Unknown Python command: ' . a:name
    echo '  Use :NeoPythonList to see registered commands.'
    echohl None
    return
  endif

  let entry = s:registry[a:name]

  " Inject the neofinder helper module before running user code
  let preamble = s:python_preamble()

  try
    if entry.file !=# ''
      " Source from file -- run preamble first, then the file
      execute 'python3 ' . preamble
      execute 'py3file ' . fnameescape(entry.file)
    else
      " Run inline code
      let code = preamble . "\n" . entry.code
      execute 'python3 << NEOFINDERPY3END' . "\n" . code . "\nNEOFINDERPY3END"
    endif
  catch
    echohl ErrorMsg
    echo '[NeoFinder] Python error in "' . a:name . '": ' . v:exception
    echohl None
  endtry
endfunction

" ---------------------------------------------------------------------------
" unregister({name})
" ---------------------------------------------------------------------------
function! neofinder#python#unregister(name) abort
  if has_key(s:registry, a:name)
    call remove(s:registry, a:name)
    return 1
  endif
  return 0
endfunction

" ---------------------------------------------------------------------------
" list()  -- return list of registered command names
" ---------------------------------------------------------------------------
function! neofinder#python#list() abort
  return keys(s:registry)
endfunction

" ---------------------------------------------------------------------------
" list_detailed()  -- return list of [name, desc] pairs
" ---------------------------------------------------------------------------
function! neofinder#python#list_detailed() abort
  let result = []
  for [name, entry] in items(s:registry)
    let src = entry.file !=# '' ? '(file) ' . fnamemodify(entry.file, ':t') : '(inline)'
    call add(result, printf('  %-20s  %s  %s', name, src, entry.desc))
  endfor
  return sort(result)
endfunction

" ---------------------------------------------------------------------------
" show_list()  -- pretty-print all commands to the user
" ---------------------------------------------------------------------------
function! neofinder#python#show_list() abort
  if empty(s:registry)
    echo '[NeoFinder] No Python commands registered.'
    echo '  Use neofinder#python#register("Name", "python_code") to add one.'
    return
  endif
  echohl NeoFinderPrompt
  echo '  NeoFinder Python Commands'
  echo '  ' . repeat('=', 50)
  echohl None
  for line in neofinder#python#list_detailed()
    echo line
  endfor
  echo ''
  echo '  Run with:  :NeoPythonExec <name>'
  echo '  Bind with: :NeoPythonBind <name> <key>'
endfunction

" ---------------------------------------------------------------------------
" bind({name}, {key})
"   Create a normal-mode mapping for a Python command.
" ---------------------------------------------------------------------------
function! neofinder#python#bind(name, key) abort
  if !has_key(s:registry, a:name)
    echohl ErrorMsg
    echo '[NeoFinder] Unknown Python command: ' . a:name
    echohl None
    return
  endif
  execute printf('nnoremap <silent> %s :NeoPythonExec %s<CR>', a:key, a:name)
  echo printf('[NeoFinder] Bound %s -> :NeoPythonExec %s', a:key, a:name)
endfunction

" ---------------------------------------------------------------------------
" Command completion function
" ---------------------------------------------------------------------------
function! neofinder#python#complete(lead, line, pos) abort
  return filter(keys(s:registry), 'v:val =~# "^" . a:lead')
endfunction

" ---------------------------------------------------------------------------
" Python preamble -- injected before every command execution.
" Provides a `neofinder` helper object with useful accessors.
" ---------------------------------------------------------------------------
function! s:python_preamble() abort
  return join([
        \ 'import vim as _vim',
        \ 'class _NeoFinderHelper:',
        \ '    @property',
        \ '    def current_file(self):',
        \ '        return _vim.eval("expand(\"%:p\")")',
        \ '    @property',
        \ '    def current_dir(self):',
        \ '        return _vim.eval("getcwd()")',
        \ '    @property',
        \ '    def current_line(self):',
        \ '        return _vim.current.line',
        \ '    @property',
        \ '    def current_buffer(self):',
        \ '        return list(_vim.current.buffer)',
        \ '    @property',
        \ '    def theme(self):',
        \ '        return _vim.eval("get(g:neofinder, \"theme\", \"matrix\")")',
        \ '    def echo(self, msg):',
        \ '        _vim.command("echohl NeoFinderPrompt")',
        \ '        _vim.command("echo \"[NeoFinder] " + str(msg).replace("\"", "\\\"") + "\"")',
        \ '        _vim.command("echohl None")',
        \ '    def run(self, cmd):',
        \ '        import subprocess',
        \ '        return subprocess.run(cmd, shell=True, capture_output=True, text=True)',
        \ '    def open_file(self, path):',
        \ '        _vim.command("edit " + path)',
        \ 'nf = _NeoFinderHelper()',
        \ ], "\n")
endfunction

" ---------------------------------------------------------------------------
" Load user commands from ~/.neofinder/python/ on first use
" ---------------------------------------------------------------------------
let s:autoloaded = 0
function! neofinder#python#autoload() abort
  if s:autoloaded
    return
  endif
  let s:autoloaded = 1
  let dir = expand('~/.neofinder/python')
  if !isdirectory(dir)
    return
  endif
  " Source any .vim registration files
  let vimfiles = glob(dir . '/*.vim', 0, 1)
  for f in vimfiles
    try
      execute 'source ' . fnameescape(f)
    catch
    endtry
  endfor
  " Auto-register any .py files as commands (filename = command name)
  let pyfiles = glob(dir . '/*.py', 0, 1)
  for f in pyfiles
    let name = fnamemodify(f, ':t:r')
    " Convert snake_case to PascalCase for command name
    let parts = split(name, '_')
    let cmd_name = join(map(parts, 'toupper(v:val[0]) . v:val[1:]'), '')
    if !has_key(s:registry, cmd_name)
      call neofinder#python#register_file(cmd_name, f, 'Auto-loaded from ~/.neofinder/python/')
    endif
  endfor
endfunction
