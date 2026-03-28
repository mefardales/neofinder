" neofinder#  -- main autoload entry point
" Dispatches to sources, launches the core UI, and provides :NeoHelp.

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
" :NeoHelp  --  dynamic command / keybinding reference
" ---------------------------------------------------------------------------
function! neofinder#help() abort
  let lines = [
        \ '  NeoFinder  - Matrix Edition  v1.0.0',
        \ '  =====================================',
        \ '',
        \ '  COMMANDS',
        \ '  --------',
        \ '  :NeoFinder        fuzzy file finder        <Leader>ff',
        \ '  :NeoConfigs       config files (/etc,~/)   <Leader>fc',
        \ '  :NeoLogs          /var/log browser          <Leader>fl',
        \ '  :NeoServices      systemd units             <Leader>fs',
        \ '  :NeoJournal       journalctl search         <Leader>fj',
        \ '  :NeoHosts         SSH hosts                 <Leader>fh',
        \ '  :NeoAnsible       playbooks & roles         <Leader>fa',
        \ '  :NeoTags          tagged/bookmarked files   <Leader>ft',
        \ '  :NeoTag           tag current file          <Leader>fT',
        \ '  :NeoUntag         untag current file',
        \ '',
        \ '  BUFFER & TAB MANAGER',
        \ '  --------------------',
        \ '  :NeoBuffers       open buffer list          <Leader>fb',
        \ '  :NeoTabGroups     tab groups (tmux-like)    <Leader>fg',
        \ '  :NeoGroupCreate   create named tab group',
        \ '  :NeoGroupAdd      add tab to group',
        \ '  :NeoGroupRemove   remove tab from group',
        \ '  :NeoTerminal      open terminal             <Leader>fR',
        \ '  :NeoRun {cmd}     run command in terminal',
        \ '',
        \ '  :NeoConfig        settings panel             <Leader>fS',
        \ '  :NeoHelp          this help                 <Leader>f?',
        \ '',
        \ '  INSIDE THE FINDER',
        \ '  -----------------',
        \ '  <CR>              open file / execute',
        \ '  <C-v>             open in vertical split',
        \ '  <C-x>             open in horizontal split',
        \ '  <C-s>             sudoedit',
        \ '  <C-t>             tail -f  (logs)',
        \ '  <C-r>             systemctl restart (services)',
        \ '  <C-h>             ssh (hosts)',
        \ '  <Tab>             toggle multi-select',
        \ '  <C-a>             select all',
        \ '  <C-d>             delete buffer (buffers) / deselect all',
        \ '  <C-j> / <C-n>     next item',
        \ '  <C-k> / <C-p>     previous item',
        \ '  Left Arrow        shrink preview pane',
        \ '  Right Arrow       grow preview pane',
        \ '  <F1>              open settings panel',
        \ '  <Esc> / <C-c>     close',
        \ '',
        \ '  THEMES: ' . join(neofinder#theme#list(), ', '),
        \ '  Active: ' . get(g:neofinder, 'theme', 'matrix'),
        \ '  Backend: ' . neofinder#backend(),
        \ ]

  call neofinder#core#run('help', lines, '')
endfunction
