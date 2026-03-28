" neofinder#tags  -- persistent file tagging / bookmarking
"
" Tags are stored one-per-line in ~/.neofinder/tags (configurable).

" ---------------------------------------------------------------------------
" Ensure tag directory and file exist
" ---------------------------------------------------------------------------
function! s:ensure_tag_file() abort
  let tagfile = get(g:neofinder, 'tag_file', expand('~/.neofinder/tags'))
  let dir = fnamemodify(tagfile, ':h')
  if !isdirectory(dir)
    call mkdir(dir, 'p', 0700)
  endif
  if !filereadable(tagfile)
    call writefile([], tagfile)
  endif
  return tagfile
endfunction

" ---------------------------------------------------------------------------
" Read all tags
" ---------------------------------------------------------------------------
function! neofinder#tags#list() abort
  let tagfile = s:ensure_tag_file()
  let lines = readfile(tagfile)
  return filter(lines, 'v:val !=# ""')
endfunction

" ---------------------------------------------------------------------------
" Tag a file path
" ---------------------------------------------------------------------------
function! neofinder#tags#add(path) abort
  let tagfile = s:ensure_tag_file()
  let tags = neofinder#tags#list()
  let fullpath = fnamemodify(a:path, ':p')
  if index(tags, fullpath) < 0
    call add(tags, fullpath)
    call writefile(tags, tagfile)
    echohl NeoFinderPrompt
    echo '  [NeoFinder] Tagged: ' . fullpath
    echohl None
  else
    echohl NeoFinderStatus
    echo '  [NeoFinder] Already tagged: ' . fullpath
    echohl None
  endif
endfunction

" ---------------------------------------------------------------------------
" Untag a file path
" ---------------------------------------------------------------------------
function! neofinder#tags#remove(path) abort
  let tagfile = s:ensure_tag_file()
  let tags = neofinder#tags#list()
  let fullpath = fnamemodify(a:path, ':p')
  let idx = index(tags, fullpath)
  if idx >= 0
    call remove(tags, idx)
    call writefile(tags, tagfile)
    echohl NeoFinderPrompt
    echo '  [NeoFinder] Untagged: ' . fullpath
    echohl None
  else
    echohl NeoFinderStatus
    echo '  [NeoFinder] Not tagged: ' . fullpath
    echohl None
  endif
endfunction

" ---------------------------------------------------------------------------
" Tag / untag current buffer file
" ---------------------------------------------------------------------------
function! neofinder#tags#tag_current() abort
  let path = expand('%:p')
  if path ==# ''
    echohl ErrorMsg
    echo '  [NeoFinder] No file in current buffer'
    echohl None
    return
  endif
  call neofinder#tags#add(path)
endfunction

function! neofinder#tags#untag_current() abort
  let path = expand('%:p')
  if path ==# ''
    echohl ErrorMsg
    echo '  [NeoFinder] No file in current buffer'
    echohl None
    return
  endif
  call neofinder#tags#remove(path)
endfunction
