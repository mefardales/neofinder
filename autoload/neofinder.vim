" neofinder#  -- main autoload entry point
" Dispatches to sources, launches the core UI, command palette, and help.

" ---------------------------------------------------------------------------
" Backend detection (cached)
" ---------------------------------------------------------------------------
let s:backend = ''

function! neofinder#backend() abort
  if s:backend !=# ''
    return s:backend
  endif
  if executable('rg')
    let s:backend = 'rg'
  elseif executable('fd')
    let s:backend = 'fd'
  else
    let s:backend = 'find'
  endif
  return s:backend
endfunction

" ---------------------------------------------------------------------------
" Build ignore flags for the detected backend
" ---------------------------------------------------------------------------
function! neofinder#ignore_flags() abort
  let ignores = get(g:neofinder, 'ignore', [])
  let be = neofinder#backend()
  let flags = []
  if be ==# 'rg'
    for p in ignores
      call add(flags, '--glob=!' . shellescape(p))
    endfor
  elseif be ==# 'fd'
    for p in ignores
      call add(flags, '-E ' . shellescape(p))
    endfor
  else
    for p in ignores
      call add(flags, '-not -path ' . shellescape('*' . p . '*'))
    endfor
  endif
  return join(flags, ' ')
endfunction

" ---------------------------------------------------------------------------
" open({source} [, {initial_query}])
" ---------------------------------------------------------------------------
function! neofinder#open(source, ...) abort
  let query = a:0 ? a:1 : ''
  let items = neofinder#sources#gather(a:source)
  call neofinder#core#run(a:source, items, query)
endfunction

" ---------------------------------------------------------------------------
" Browse a specific directory (or cwd if no arg)
" ---------------------------------------------------------------------------
function! neofinder#browse(...) abort
  let dir = a:0 ? a:1 : ''
  if dir ==# '' || !isdirectory(dir)
    let dir = getcwd()
  endif
  let dir = fnamemodify(dir, ':p')
  let g:neofinder._browse_dir = dir
  call neofinder#open('browse', '')
endfunction

" ---------------------------------------------------------------------------
" Command palette -- all actions in one fuzzy list
" ---------------------------------------------------------------------------
" Each entry:  'display label' -> [action_type, action_arg]
let s:palette_actions = {}

function! neofinder#palette(...) abort
  let query = a:0 ? a:1 : ''

  let s:palette_actions = {}
  let entries = []

  let sources = [
        \ ['Files           :ff   fuzzy file finder',            'source', 'files'],
        \ ['Browse          :fd   directory browser',            'source', 'browse'],
        \ ['Buffers         :fb   open buffers',                 'source', 'buffers'],
        \ ['Tags            :fg   tagged file groups',           'source', 'taggroups'],
        \ ['Hosts           :fh   SSH hosts',                    'source', 'hosts'],
        \ ['Terminal        :fR   open terminal',                'source', 'terminal'],
        \ ['Configs         :fc   /etc ~/.config',               'source', 'configs'],
        \ ['Logs            :fl   /var/log',                     'source', 'logs'],
        \ ['Services        :fs   systemd units',                'source', 'services'],
        \ ['Scripts         :fk   ~/bin scripts',                'source', 'scripts'],
        \ ['Commands        :fr   run commands',                 'source', 'commands'],
        \ ]

  for [label, type, arg] in sources
    call add(entries, label)
    let s:palette_actions[label] = [type, arg]
  endfor

  call neofinder#core#run('palette', entries, query)
endfunction

" ---------------------------------------------------------------------------
" Palette dispatcher -- called by core when user accepts a palette item
" ---------------------------------------------------------------------------
" ---------------------------------------------------------------------------
" Palette dispatcher -- called by actions.vim when user selects a palette item
"
" Source actions → open with nav stack (Backspace returns to palette)
" Quick actions  → execute then auto-reopen palette so user stays in flow
" Terminal/run   → execute and exit (user is now in terminal)
" ---------------------------------------------------------------------------
function! neofinder#palette_dispatch(selected) abort
  if !has_key(s:palette_actions, a:selected)
    return
  endif
  let [type, arg] = s:palette_actions[a:selected]

  if type ==# 'source'
    if arg ==# 'terminal'
      " Terminal is a final destination, no return
      call neofinder#buffers#open_terminal()
    else
      " Open source WITH nav stack → Backspace returns to palette
      let items = neofinder#sources#gather(arg)
      call neofinder#core#run_from_palette(arg, items, '')
    endif

  elseif type ==# 'theme'
    " Quick action: switch theme and reopen palette
    let g:neofinder.theme = arg
    call neofinder#theme#apply()
    redraw
    echohl NeoFinderPrompt
    echo '  Theme: ' . arg
    echohl None
    sleep 400m
    call neofinder#palette('')

  elseif type ==# 'call'
    " Execute the call
    execute 'call ' . arg
    " Reopen palette for actions that don't open a new UI
    " (tag, untag, statusline toggle, python list, etc.)
    " But NOT for settings/help which open their own UI
    if arg !~# 'config#open\|help()'
      sleep 300m
      call neofinder#palette('')
    endif

  elseif type ==# 'python'
    call neofinder#python#exec(arg)
    " Return to palette after python command
    sleep 300m
    call neofinder#palette('')

  elseif type ==# 'run'
    let cmd = input('Command: ')
    if cmd !=# ''
      call neofinder#buffers#open_terminal(cmd)
    else
      " User cancelled, return to palette
      call neofinder#palette('')
    endif
  endif
endfunction

" ---------------------------------------------------------------------------
" :Neo help -- quick reference via palette
" ---------------------------------------------------------------------------
function! neofinder#help() abort
  let lines = [
        \ '  NeoFinder  - Matrix Edition  v2.0.0',
        \ '  =====================================',
        \ '',
        \ '  COMMANDS (type : then Tab)',
        \ '  --------------------------',
        \ '  :Neo          command palette (search everything)',
        \ '  :Nd [path]    directory browser <Leader>fd',
        \ '  :Nf           files           <Leader>ff',
        \ '  :Nc           configs         <Leader>fc',
        \ '  :Nl           logs            <Leader>fl',
        \ '  :Ns           services        <Leader>fs',
        \ '  :Nj           journal         <Leader>fj',
        \ '  :Nh           hosts/ssh       <Leader>fh',
        \ '  :Na           ansible         <Leader>fa',
        \ '  :Nk           scripts         <Leader>fk',
        \ '  :Nw           wordlists       <Leader>fw',
        \ '  :Nx           exploits        <Leader>fx',
        \ '  :Nt           tag file        <Leader>ft',
        \ '  :Nu           untag file      <Leader>fu',
        \ '  :NTg          tag groups      <Leader>fg',
        \ '  :NTa          all tags        <Leader>fT',
        \ '  :Nb           buffers         <Leader>fb',
        \ '  :Ng           tab groups      <Leader>fG',
        \ '  :Nr           terminal        <Leader>fR',
        \ '',
        \ '  <Leader>n     open palette',
        \ '',
        \ '  INSIDE THE FINDER',
        \ '  -----------------',
        \ '  Up/Down, C-k/C-j   navigate',
        \ '  <CR>                open / execute',
        \ '  <C-v>               vertical split',
        \ '  <C-x>               horizontal split',
        \ '  <C-s>               sudoedit',
        \ '  <C-t>               tail -f  (logs)',
        \ '  <C-r>               systemctl restart',
        \ '  <C-h>               ssh connect (hosts)',
        \ '  <Tab>               toggle panel/editor',
        \ '  <C-Space>           multi-select toggle',
        \ '  <C-a>               select all',
        \ '  <C-d>               deselect / delete buf',
        \ '  Left/Right          resize preview',
        \ '  <F1>                settings panel',
        \ '  <Esc>               close',
        \ '',
        \ '  THEMES: ' . join(neofinder#theme#list(), ', '),
        \ '  Active: ' . get(g:neofinder, 'theme', 'matrix'),
        \ '  Backend: ' . neofinder#backend(),
        \ ]

  call neofinder#core#run('help', lines, '')
endfunction
