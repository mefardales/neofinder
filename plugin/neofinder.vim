" neofinder.vim - Matrix Edition fuzzy finder & sysadmin toolkit
" Maintainer: NeoFinder contributors
" Version:    2.0.0
" License:    MIT
"
" Commands:
"   :Neo          command palette (fuzzy search all actions)
"   :Nf           files       :Nc  configs     :Nl  logs
"   :Ns           services    :Nj  journal     :Nh  hosts/ssh
"   :Na           ansible     :Nt  tags        :Nb  buffers
"   :Ng           tab groups  :Nr  terminal

if exists('g:loaded_neofinder') || &compatible
  finish
endif
let g:loaded_neofinder = 1

let s:save_cpo = &cpo
set cpo&vim

" ---------------------------------------------------------------------------
" Default configuration
" ---------------------------------------------------------------------------
let s:defaults = {
      \ 'ignore': ['/proc', '/sys', '/dev', '/run', '/var/cache',
      \            '/snap', '/mnt', '/media', '.git', 'node_modules',
      \            '__pycache__', '.cache', '/lost+found'],
      \ 'max_files': 50000,
      \ 'theme': 'matrix',
      \ 'statusline': 1,
      \ 'ascii_statusline': 0,
      \ 'preview': 1,
      \ 'preview_width': 60,
      \ 'height': 15,
      \ 'tag_file': expand('~/.neofinder/tags'),
      \ 'ssh_config': expand('~/.ssh/config'),
      \ 'known_hosts': expand('~/.ssh/known_hosts'),
      \ 'config_paths': ['/etc', expand('~/.config'),
      \                  '/etc/nginx', '/etc/apache2', '/etc/httpd',
      \                  '/etc/systemd', '/etc/ansible',
      \                  expand('~/ansible'), expand('~/playbooks')],
      \ 'log_paths': ['/var/log'],
      \ 'ansible_paths': ['/etc/ansible', expand('~/ansible'),
      \                   expand('~/playbooks'), '.'],
      \ 'script_paths':  [expand('~/bin'), expand('~/scripts'),
      \                   expand('~/.local/bin'), '/usr/local/bin'],
      \ 'wordlist_paths': ['/usr/share/wordlists', '/usr/share/seclists',
      \                    expand('~/wordlists')],
      \ 'exploit_paths':  ['/usr/share/exploitdb/exploits',
      \                    '/usr/share/metasploit-framework/modules',
      \                    expand('~/exploits')],
      \ }

if !exists('g:neofinder')
  let g:neofinder = {}
endif
for [s:k, s:v] in items(s:defaults)
  if !has_key(g:neofinder, s:k)
    let g:neofinder[s:k] = s:v
  endif
endfor

" Load user config.json (overrides defaults)
call neofinder#config#load()

" ---------------------------------------------------------------------------
" Commands -- short, unique prefixes for fast tab-complete
" ---------------------------------------------------------------------------
" The palette: fuzzy search all available actions
command! -nargs=? Neo  call neofinder#palette(<q-args>)

" Direct source commands (sysadmin speed)
command! -nargs=? -complete=dir Nd call neofinder#browse(<q-args>)
command! -nargs=? Nf   call neofinder#open('files', <q-args>)
command! -nargs=? Nc   call neofinder#open('configs', <q-args>)
command! -nargs=? Nl   call neofinder#open('logs', <q-args>)
command! -nargs=? Ns   call neofinder#open('services', <q-args>)
command! -nargs=? Nj   call neofinder#open('journal', <q-args>)
command! -nargs=? Nh   call neofinder#open('hosts', <q-args>)
command! -nargs=? Na   call neofinder#open('ansible', <q-args>)
command! -nargs=? Nt   call neofinder#tags#tag_current()
command! -nargs=? Nu   call neofinder#tags#untag_current()
command! -nargs=? NTg  call neofinder#open('taggroups', <q-args>)
command! -nargs=? NTa  call neofinder#open('tags', <q-args>)
command! -nargs=? Nk   call neofinder#open('scripts', <q-args>)
command! -nargs=? Nw   call neofinder#open('wordlists', <q-args>)
command! -nargs=? Nx   call neofinder#open('exploits', <q-args>)
command! -nargs=? Nb   call neofinder#open('buffers', <q-args>)
command! -nargs=? Ng   call neofinder#open('tabgroups', <q-args>)
command! -nargs=0 Nr   call neofinder#buffers#open_terminal()
command! -nargs=? Nrun  call neofinder#open('run', <q-args>)
command! -nargs=? Nedit call neofinder#open('commands', <q-args>)

" ---------------------------------------------------------------------------
" Default mappings (override with g:neofinder.no_mappings = 1)
" ---------------------------------------------------------------------------
if !get(g:neofinder, 'no_mappings', 0)
  nnoremap <silent> <Leader>fp :Neo<CR>
  nnoremap <silent> <Leader>ff :Nf<CR>
  nnoremap <silent> <Leader>fd :Nd<CR>
  nnoremap <silent> <Leader>fg :NTg<CR>
  nnoremap <silent> <Leader>ft :Nt<CR>
  nnoremap <silent> <Leader>fu :Nu<CR>
  nnoremap <silent> <Leader>fR :Nr<CR>
  nnoremap <silent> <Leader>fr :Nrun<CR>
  nnoremap <silent> <Leader>fe :Nedit<CR>
  nnoremap <silent> <Leader>fc :call neofinder#config#open()<CR>
endif

" ---------------------------------------------------------------------------
" Command system (.py files)
" ---------------------------------------------------------------------------
command! -nargs=+ -complete=customlist,neofinder#python#complete NeoPythonExec call neofinder#python#exec(<q-args>)
command! -nargs=0 NeoPythonList call neofinder#python#show_list()
command! -nargs=+ NeoPythonBind call neofinder#python#bind(<f-args>)

" ---------------------------------------------------------------------------
" Auto-load built-in + user commands
" ---------------------------------------------------------------------------
augroup NeoFinderPython
  autocmd!
  autocmd VimEnter * call neofinder#python#autoload()
augroup END

" ---------------------------------------------------------------------------
" Apply theme globally on startup (editor + statusline + finder highlights)
" ---------------------------------------------------------------------------
augroup NeoFinderThemeStartup
  autocmd!
  autocmd VimEnter,ColorScheme * call neofinder#theme#apply()
augroup END

call neofinder#theme#apply()

let &cpo = s:save_cpo
unlet s:save_cpo
