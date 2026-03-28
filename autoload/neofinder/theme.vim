" neofinder#theme  -- Multi-theme system with custom theme support
"
" Built-in themes: matrix, dark, cyberpunk, default
" Custom themes:   ~/.neofinder/themes/<name>.vim  (dictionary-based)
"
" Each theme is a dictionary with keys for each highlight group.
" Groups: Normal, Prompt, Status, Cursor, Selected, Border,
"         Preview, PreviewTitle, Keyword, String, Comment, Number,
"         Type, Function, Operator, Special

" ---------------------------------------------------------------------------
" Built-in theme definitions
" ---------------------------------------------------------------------------
let s:themes = {}

" Matrix -- green on black (the original)
let s:themes.matrix = {
      \ 'Normal':       {'ctermfg': 46,  'ctermbg': 0,  'guifg': '#00FF41', 'guibg': '#000000'},
      \ 'Prompt':       {'ctermfg': 46,  'ctermbg': 0,  'guifg': '#00FF41', 'guibg': '#0A0A0A', 'cterm': 'bold', 'gui': 'bold'},
      \ 'Status':       {'ctermfg': 34,  'ctermbg': 0,  'guifg': '#00CC00', 'guibg': '#0A0A0A'},
      \ 'Cursor':       {'ctermfg': 0,   'ctermbg': 46, 'guifg': '#000000', 'guibg': '#00FF41', 'cterm': 'bold', 'gui': 'bold'},
      \ 'Selected':     {'ctermfg': 82,  'ctermbg': 22, 'guifg': '#55FF55', 'guibg': '#003300', 'cterm': 'bold', 'gui': 'bold'},
      \ 'Border':       {'ctermfg': 28,  'ctermbg': 0,  'guifg': '#008800', 'guibg': '#000000'},
      \ 'Preview':      {'ctermfg': 46,  'ctermbg': 0,  'guifg': '#00FF41', 'guibg': '#0A0A0A'},
      \ 'PreviewTitle': {'ctermfg': 46,  'ctermbg': 0,  'guifg': '#00FF41', 'guibg': '#0A0A0A', 'cterm': 'bold', 'gui': 'bold'},
      \ 'Keyword':      {'ctermfg': 46,  'ctermbg': 0,  'guifg': '#00FF41', 'guibg': '#0A0A0A', 'cterm': 'bold', 'gui': 'bold'},
      \ 'String':       {'ctermfg': 34,  'ctermbg': 0,  'guifg': '#00CC00', 'guibg': '#0A0A0A'},
      \ 'Comment':      {'ctermfg': 22,  'ctermbg': 0,  'guifg': '#006600', 'guibg': '#0A0A0A', 'cterm': 'italic', 'gui': 'italic'},
      \ 'Number':       {'ctermfg': 48,  'ctermbg': 0,  'guifg': '#00FF99', 'guibg': '#0A0A0A'},
      \ 'Type':         {'ctermfg': 40,  'ctermbg': 0,  'guifg': '#00DD33', 'guibg': '#0A0A0A'},
      \ 'Function':     {'ctermfg': 82,  'ctermbg': 0,  'guifg': '#55FF55', 'guibg': '#0A0A0A', 'cterm': 'bold', 'gui': 'bold'},
      \ 'Operator':     {'ctermfg': 28,  'ctermbg': 0,  'guifg': '#008800', 'guibg': '#0A0A0A'},
      \ 'Special':      {'ctermfg': 48,  'ctermbg': 0,  'guifg': '#00FF99', 'guibg': '#0A0A0A', 'cterm': 'bold', 'gui': 'bold'},
      \ }

" Dark -- subtle gray/white on dark background
let s:themes.dark = {
      \ 'Normal':       {'ctermfg': 250, 'ctermbg': 234, 'guifg': '#BCBCBC', 'guibg': '#1C1C1C'},
      \ 'Prompt':       {'ctermfg': 255, 'ctermbg': 234, 'guifg': '#EEEEEE', 'guibg': '#1C1C1C', 'cterm': 'bold', 'gui': 'bold'},
      \ 'Status':       {'ctermfg': 245, 'ctermbg': 235, 'guifg': '#8A8A8A', 'guibg': '#262626'},
      \ 'Cursor':       {'ctermfg': 234, 'ctermbg': 75,  'guifg': '#1C1C1C', 'guibg': '#5FAFFF', 'cterm': 'bold', 'gui': 'bold'},
      \ 'Selected':     {'ctermfg': 117, 'ctermbg': 237, 'guifg': '#87D7FF', 'guibg': '#3A3A3A', 'cterm': 'bold', 'gui': 'bold'},
      \ 'Border':       {'ctermfg': 240, 'ctermbg': 234, 'guifg': '#585858', 'guibg': '#1C1C1C'},
      \ 'Preview':      {'ctermfg': 250, 'ctermbg': 235, 'guifg': '#BCBCBC', 'guibg': '#262626'},
      \ 'PreviewTitle': {'ctermfg': 75,  'ctermbg': 235, 'guifg': '#5FAFFF', 'guibg': '#262626', 'cterm': 'bold', 'gui': 'bold'},
      \ 'Keyword':      {'ctermfg': 168, 'ctermbg': 235, 'guifg': '#D75F87', 'guibg': '#262626', 'cterm': 'bold', 'gui': 'bold'},
      \ 'String':       {'ctermfg': 108, 'ctermbg': 235, 'guifg': '#87AF87', 'guibg': '#262626'},
      \ 'Comment':      {'ctermfg': 242, 'ctermbg': 235, 'guifg': '#6C6C6C', 'guibg': '#262626', 'cterm': 'italic', 'gui': 'italic'},
      \ 'Number':       {'ctermfg': 173, 'ctermbg': 235, 'guifg': '#D7875F', 'guibg': '#262626'},
      \ 'Type':         {'ctermfg': 110, 'ctermbg': 235, 'guifg': '#87AFD7', 'guibg': '#262626'},
      \ 'Function':     {'ctermfg': 75,  'ctermbg': 235, 'guifg': '#5FAFFF', 'guibg': '#262626', 'cterm': 'bold', 'gui': 'bold'},
      \ 'Operator':     {'ctermfg': 250, 'ctermbg': 235, 'guifg': '#BCBCBC', 'guibg': '#262626'},
      \ 'Special':      {'ctermfg': 215, 'ctermbg': 235, 'guifg': '#FFAF5F', 'guibg': '#262626'},
      \ }

" Cyberpunk -- magenta/cyan neon on dark
let s:themes.cyberpunk = {
      \ 'Normal':       {'ctermfg': 201, 'ctermbg': 233, 'guifg': '#FF00FF', 'guibg': '#121212'},
      \ 'Prompt':       {'ctermfg': 51,  'ctermbg': 233, 'guifg': '#00FFFF', 'guibg': '#121212', 'cterm': 'bold', 'gui': 'bold'},
      \ 'Status':       {'ctermfg': 93,  'ctermbg': 233, 'guifg': '#8700FF', 'guibg': '#121212'},
      \ 'Cursor':       {'ctermfg': 0,   'ctermbg': 51,  'guifg': '#000000', 'guibg': '#00FFFF', 'cterm': 'bold', 'gui': 'bold'},
      \ 'Selected':     {'ctermfg': 218, 'ctermbg': 53,  'guifg': '#FFAFD7', 'guibg': '#5F005F', 'cterm': 'bold', 'gui': 'bold'},
      \ 'Border':       {'ctermfg': 129, 'ctermbg': 233, 'guifg': '#AF00FF', 'guibg': '#121212'},
      \ 'Preview':      {'ctermfg': 201, 'ctermbg': 234, 'guifg': '#FF00FF', 'guibg': '#1C1C1C'},
      \ 'PreviewTitle': {'ctermfg': 51,  'ctermbg': 234, 'guifg': '#00FFFF', 'guibg': '#1C1C1C', 'cterm': 'bold', 'gui': 'bold'},
      \ 'Keyword':      {'ctermfg': 51,  'ctermbg': 234, 'guifg': '#00FFFF', 'guibg': '#1C1C1C', 'cterm': 'bold', 'gui': 'bold'},
      \ 'String':       {'ctermfg': 207, 'ctermbg': 234, 'guifg': '#FF5FFF', 'guibg': '#1C1C1C'},
      \ 'Comment':      {'ctermfg': 240, 'ctermbg': 234, 'guifg': '#585858', 'guibg': '#1C1C1C', 'cterm': 'italic', 'gui': 'italic'},
      \ 'Number':       {'ctermfg': 214, 'ctermbg': 234, 'guifg': '#FFAF00', 'guibg': '#1C1C1C'},
      \ 'Type':         {'ctermfg': 129, 'ctermbg': 234, 'guifg': '#AF00FF', 'guibg': '#1C1C1C'},
      \ 'Function':     {'ctermfg': 87,  'ctermbg': 234, 'guifg': '#5FFFFF', 'guibg': '#1C1C1C', 'cterm': 'bold', 'gui': 'bold'},
      \ 'Operator':     {'ctermfg': 201, 'ctermbg': 234, 'guifg': '#FF00FF', 'guibg': '#1C1C1C'},
      \ 'Special':      {'ctermfg': 226, 'ctermbg': 234, 'guifg': '#FFFF00', 'guibg': '#1C1C1C', 'cterm': 'bold', 'gui': 'bold'},
      \ }

" Default -- Vim's native colors, no background override
let s:themes.default = {
      \ 'Normal':       {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE'},
      \ 'Prompt':       {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \ 'Status':       {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE'},
      \ 'Cursor':       {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE', 'cterm': 'reverse', 'gui': 'reverse'},
      \ 'Selected':     {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \ 'Border':       {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE'},
      \ 'Preview':      {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE'},
      \ 'PreviewTitle': {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \ 'Keyword':      {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \ 'String':       {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE'},
      \ 'Comment':      {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE', 'cterm': 'italic', 'gui': 'italic'},
      \ 'Number':       {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE'},
      \ 'Type':         {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE'},
      \ 'Function':     {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE'},
      \ 'Operator':     {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE'},
      \ 'Special':      {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE'},
      \ }

" ---------------------------------------------------------------------------
" Resolve a theme dictionary by name (built-in or custom from disk)
" ---------------------------------------------------------------------------
function! neofinder#theme#get(name) abort
  " Check built-in first
  if has_key(s:themes, a:name)
    return s:themes[a:name]
  endif
  " Try loading from ~/.neofinder/themes/<name>.vim
  let path = expand('~/.neofinder/themes/' . a:name . '.vim')
  if filereadable(path)
    try
      execute 'source ' . fnameescape(path)
      " The file must define g:neofinder_custom_theme
      if exists('g:neofinder_custom_theme')
        let theme = deepcopy(g:neofinder_custom_theme)
        unlet g:neofinder_custom_theme
        return theme
      endif
    catch
    endtry
  endif
  " Fallback to matrix
  return s:themes.matrix
endfunction

" ---------------------------------------------------------------------------
" List all available theme names (built-in + custom)
" ---------------------------------------------------------------------------
function! neofinder#theme#list() abort
  let names = keys(s:themes)
  " Scan custom themes directory
  let dir = expand('~/.neofinder/themes')
  if isdirectory(dir)
    let files = glob(dir . '/*.vim', 0, 1)
    for f in files
      let name = fnamemodify(f, ':t:r')
      if index(names, name) < 0
        call add(names, name)
      endif
    endfor
  endif
  return sort(names)
endfunction

" ---------------------------------------------------------------------------
" Apply a single highlight group from a theme dictionary entry
" ---------------------------------------------------------------------------
function! s:apply_hl(group_name, hl_name, attrs) abort
  let cmd = 'highlight ' . a:hl_name
  let cmd .= ' ctermfg=' . get(a:attrs, 'ctermfg', 'NONE')
  let cmd .= ' ctermbg=' . get(a:attrs, 'ctermbg', 'NONE')
  let cmd .= ' guifg='   . get(a:attrs, 'guifg',   'NONE')
  let cmd .= ' guibg='   . get(a:attrs, 'guibg',   'NONE')
  if has_key(a:attrs, 'cterm')
    let cmd .= ' cterm=' . a:attrs.cterm
  else
    let cmd .= ' cterm=NONE'
  endif
  if has_key(a:attrs, 'gui')
    let cmd .= ' gui=' . a:attrs.gui
  else
    let cmd .= ' gui=NONE'
  endif
  execute cmd
endfunction

" ---------------------------------------------------------------------------
" apply() -- set all NeoFinder* highlight groups from the active theme
" ---------------------------------------------------------------------------
function! neofinder#theme#apply() abort
  let name = get(g:neofinder, 'theme', 'matrix')
  let theme = neofinder#theme#get(name)

  " Map dict keys to highlight group names
  let group_map = {
        \ 'Normal':       'NeoFinderNormal',
        \ 'Prompt':       'NeoFinderPrompt',
        \ 'Status':       'NeoFinderStatus',
        \ 'Cursor':       'NeoFinderCursor',
        \ 'Selected':     'NeoFinderSelected',
        \ 'Border':       'NeoFinderBorder',
        \ 'Preview':      'NeoFinderPreview',
        \ 'PreviewTitle': 'NeoFinderPreviewTitle',
        \ 'Keyword':      'NeoFinderKeyword',
        \ 'String':       'NeoFinderString',
        \ 'Comment':      'NeoFinderComment',
        \ 'Number':       'NeoFinderNumber',
        \ 'Type':         'NeoFinderType',
        \ 'Function':     'NeoFinderFunction',
        \ 'Operator':     'NeoFinderOperator',
        \ 'Special':      'NeoFinderSpecial',
        \ }

  for [key, hlname] in items(group_map)
    if has_key(theme, key)
      call s:apply_hl(key, hlname, theme[key])
    endif
  endfor
endfunction

" ---------------------------------------------------------------------------
" set_buffer_highlights() -- link groups for the finder buffer
" ---------------------------------------------------------------------------
function! neofinder#theme#set_buffer_highlights() abort
  if exists('+winhighlight')
    setlocal winhighlight=Normal:NeoFinderNormal,CursorLine:NeoFinderCursor,EndOfBuffer:NeoFinderNormal
  endif
endfunction

" ---------------------------------------------------------------------------
" set_preview_highlights() -- link groups for the preview buffer
" ---------------------------------------------------------------------------
function! neofinder#theme#set_preview_highlights() abort
  if exists('+winhighlight')
    setlocal winhighlight=Normal:NeoFinderPreview,EndOfBuffer:NeoFinderPreview
  endif

  " Link standard syntax groups to our themed variants
  highlight! link Comment     NeoFinderComment
  highlight! link String      NeoFinderString
  highlight! link Number      NeoFinderNumber
  highlight! link Float       NeoFinderNumber
  highlight! link Keyword     NeoFinderKeyword
  highlight! link Statement   NeoFinderKeyword
  highlight! link Conditional NeoFinderKeyword
  highlight! link Repeat      NeoFinderKeyword
  highlight! link Type        NeoFinderType
  highlight! link Function    NeoFinderFunction
  highlight! link Identifier  NeoFinderFunction
  highlight! link Operator    NeoFinderOperator
  highlight! link Special     NeoFinderSpecial
  highlight! link PreProc     NeoFinderSpecial
  highlight! link Constant    NeoFinderNumber
  highlight! link Todo        NeoFinderSelected
endfunction

" ---------------------------------------------------------------------------
" Save a theme dictionary to ~/.neofinder/themes/<name>.vim
" ---------------------------------------------------------------------------
function! neofinder#theme#save(name, theme_dict) abort
  let dir = expand('~/.neofinder/themes')
  if !isdirectory(dir)
    call mkdir(dir, 'p', 0700)
  endif
  let path = dir . '/' . a:name . '.vim'
  let lines = ['" NeoFinder custom theme: ' . a:name,
        \ '" Auto-generated -- edit freely',
        \ '',
        \ 'let g:neofinder_custom_theme = {']
  for [key, attrs] in items(a:theme_dict)
    let parts = []
    for [ak, av] in items(attrs)
      if type(av) == type(0)
        call add(parts, printf("'%s': %d", ak, av))
      else
        call add(parts, printf("'%s': '%s'", ak, av))
      endif
    endfor
    call add(lines, printf("      \\ '%s': {%s},", key, join(parts, ', ')))
  endfor
  call add(lines, '      \ }')
  call writefile(lines, path)
  return path
endfunction

" ---------------------------------------------------------------------------
" Register a custom theme at runtime (without saving to disk)
" ---------------------------------------------------------------------------
function! neofinder#theme#register(name, theme_dict) abort
  let s:themes[a:name] = a:theme_dict
endfunction
