" neofinder.vim - Matrix Edition fuzzy finder & sysadmin toolkit
" Maintainer: NeoFinder contributors
" Version:    1.0.0
" License:    MIT

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
      \ }

if !exists('g:neofinder')
  let g:neofinder = {}
endif
for [s:k, s:v] in items(s:defaults)
  if !has_key(g:neofinder, s:k)
    let g:neofinder[s:k] = s:v
  endif
endfor

" ---------------------------------------------------------------------------
" Commands
" ---------------------------------------------------------------------------
command! -nargs=? NeoFinder   call neofinder#open('files', <q-args>)
command! -nargs=? NeoConfigs  call neofinder#open('configs', <q-args>)
command! -nargs=? NeoLogs     call neofinder#open('logs', <q-args>)
command! -nargs=? NeoServices call neofinder#open('services', <q-args>)
command! -nargs=? NeoJournal  call neofinder#open('journal', <q-args>)
command! -nargs=? NeoHosts    call neofinder#open('hosts', <q-args>)
command! -nargs=? NeoAnsible  call neofinder#open('ansible', <q-args>)
command! -nargs=? NeoTags     call neofinder#open('tags', <q-args>)
command! -nargs=0 NeoTag      call neofinder#tags#tag_current()
command! -nargs=0 NeoUntag    call neofinder#tags#untag_current()
command! -nargs=0 NeoHelp     call neofinder#help()

" ---------------------------------------------------------------------------
" Default mappings (override with g:neofinder.no_mappings = 1)
" ---------------------------------------------------------------------------
if !get(g:neofinder, 'no_mappings', 0)
  nnoremap <silent> <Leader>ff :NeoFinder<CR>
  nnoremap <silent> <Leader>fc :NeoConfigs<CR>
  nnoremap <silent> <Leader>fl :NeoLogs<CR>
  nnoremap <silent> <Leader>fs :NeoServices<CR>
  nnoremap <silent> <Leader>fj :NeoJournal<CR>
  nnoremap <silent> <Leader>fh :NeoHosts<CR>
  nnoremap <silent> <Leader>fa :NeoAnsible<CR>
  nnoremap <silent> <Leader>ft :NeoTags<CR>
  nnoremap <silent> <Leader>fT :NeoTag<CR>
  nnoremap <silent> <Leader>f? :NeoHelp<CR>
endif

let &cpo = s:save_cpo
unlet s:save_cpo
