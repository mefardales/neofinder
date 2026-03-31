" neofinder#indexer  -- Vim wrapper for the Python file indexer

let s:loaded = 0
let s:indexer_path = substitute(expand('<sfile>:p:h') . '/indexer.py', '\\', '/', 'g')

function! s:ensure_loaded() abort
  if s:loaded || !has('python3')
    return s:loaded
  endif
  try
    execute 'py3file ' . fnameescape(s:indexer_path)
    let s:loaded = 1
  catch
  endtry
  return s:loaded
endfunction

" Start indexing a directory in background
function! neofinder#indexer#start(dir) abort
  if !s:ensure_loaded() | return | endif
  let dir = substitute(fnamemodify(a:dir, ':p'), '\\', '/', 'g')
  let max = get(g:neofinder, 'max_files', 50000)
  execute 'python3 index_dir_async("' . escape(dir, '"') . '", ' . max . ')'
endfunction

" Search the index. Returns list of relative paths.
function! neofinder#indexer#search(dir, query) abort
  if !s:ensure_loaded() | return [] | endif
  let dir = substitute(fnamemodify(a:dir, ':p'), '\\', '/', 'g')
  let query = escape(a:query, '"\\')
  let result = py3eval('search_index("' . dir . '", "' . query . '")')
  return result
endfunction

" Get file count in index
function! neofinder#indexer#count(dir) abort
  if !s:ensure_loaded() | return 0 | endif
  let dir = substitute(fnamemodify(a:dir, ':p'), '\\', '/', 'g')
  return py3eval('index_count("' . dir . '")')
endfunction

" Check if indexing is in progress
function! neofinder#indexer#is_indexing() abort
  if !s:ensure_loaded() | return 0 | endif
  return py3eval('is_indexing()')
endfunction

" Clear index cache
function! neofinder#indexer#clear(...) abort
  if !s:ensure_loaded() | return | endif
  if a:0
    let dir = substitute(fnamemodify(a:1, ':p'), '\\', '/', 'g')
    execute 'python3 clear_index("' . escape(dir, '"') . '")'
  else
    execute 'python3 clear_index()'
  endif
endfunction
