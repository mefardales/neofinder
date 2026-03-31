" neofinder#theme  -- Global + NeoFinder multi-theme system
"
" Themes affect the ENTIRE Vim editor: Normal, StatusLine, CursorLine,
" LineNr, Visual, Pmenu, syntax groups, etc.  Not just NeoFinder windows.
"
" Built-in theme:  matrix
" Custom themes:   ~/.neofinder/themes/<name>.vim  (dictionary-based)

" ---------------------------------------------------------------------------
" Built-in theme definitions
" ---------------------------------------------------------------------------
" Each theme has two sections:
"   'editor'  → global Vim highlight groups
"   'finder'  → NeoFinder-specific UI groups
"
" Editor groups:  Normal, StatusLine, StatusLineNC, CursorLine, CursorLineNr,
"                 LineNr, Visual, VertSplit, Pmenu, PmenuSel, PmenuSbar,
"                 PmenuThumb, TabLine, TabLineSel, TabLineFill, Search,
"                 IncSearch, MatchParen, NonText, EndOfBuffer, SignColumn,
"                 Comment, String, Number, Keyword, Type, Function, Operator,
"                 Special, PreProc, Constant, Identifier, Statement, Todo,
"                 Error, WarningMsg, Directory, Title, MoreMsg, Question
"
" Finder groups:  Normal, Prompt, Status, Cursor, Selected, Border,
"                 Preview, PreviewTitle

let s:themes = {}

" ===== MATRIX =====
" Palette:
"   bg=#000000  bg-alt=#01120a  darkest=#011f11  darker=#004022
"   dark=#00733d  fg=#00b25f  middle=#00cd6d  bright=#00e57a
"   hl=#00ff88  red=#cc0037  blue=#0081c7
let s:themes.matrix = {
      \ 'editor': {
      \   'Normal':       {'ctermfg': 35,  'ctermbg': 0,   'guifg': '#00b25f', 'guibg': '#000000'},
      \   'StatusLine':   {'ctermfg': 0,   'ctermbg': 35,  'guifg': '#000000', 'guibg': '#00b25f', 'cterm': 'bold', 'gui': 'bold'},
      \   'StatusLineNC': {'ctermfg': 0,   'ctermbg': 22,  'guifg': '#000000', 'guibg': '#00733d'},
      \   'CursorLine':   {'ctermfg': 'NONE', 'ctermbg': 233, 'guifg': 'NONE', 'guibg': '#01120a'},
      \   'CursorLineNr': {'ctermfg': 48,  'ctermbg': 233, 'guifg': '#00ff88', 'guibg': '#01120a', 'cterm': 'bold', 'gui': 'bold'},
      \   'LineNr':       {'ctermfg': 22,  'ctermbg': 0,   'guifg': '#004022', 'guibg': '#000000'},
      \   'Visual':       {'ctermfg': 42,  'ctermbg': 233, 'guifg': '#00cd6d', 'guibg': '#011f11'},
      \   'VertSplit':    {'ctermfg': 22,  'ctermbg': 0,   'guifg': '#004022', 'guibg': '#000000'},
      \   'Pmenu':        {'ctermfg': 35,  'ctermbg': 233, 'guifg': '#00b25f', 'guibg': '#01120a'},
      \   'PmenuSel':     {'ctermfg': 0,   'ctermbg': 48,  'guifg': '#000000', 'guibg': '#00ff88', 'cterm': 'bold', 'gui': 'bold'},
      \   'PmenuSbar':    {'ctermfg': 'NONE', 'ctermbg': 233, 'guifg': 'NONE', 'guibg': '#01120a'},
      \   'PmenuThumb':   {'ctermfg': 'NONE', 'ctermbg': 22,  'guifg': 'NONE', 'guibg': '#00733d'},
      \   'TabLine':      {'ctermfg': 22,  'ctermbg': 233, 'guifg': '#00733d', 'guibg': '#01120a'},
      \   'TabLineSel':   {'ctermfg': 0,   'ctermbg': 35,  'guifg': '#000000', 'guibg': '#00b25f', 'cterm': 'bold', 'gui': 'bold'},
      \   'TabLineFill':  {'ctermfg': 22,  'ctermbg': 233, 'guifg': '#004022', 'guibg': '#01120a'},
      \   'Search':       {'ctermfg': 0,   'ctermbg': 48,  'guifg': '#000000', 'guibg': '#00ff88', 'cterm': 'bold', 'gui': 'bold'},
      \   'IncSearch':    {'ctermfg': 0,   'ctermbg': 41,  'guifg': '#000000', 'guibg': '#00e57a', 'cterm': 'bold', 'gui': 'bold'},
      \   'MatchParen':   {'ctermfg': 48,  'ctermbg': 233, 'guifg': '#00ff88', 'guibg': '#011f11', 'cterm': 'bold,underline', 'gui': 'bold,underline'},
      \   'NonText':      {'ctermfg': 22,  'ctermbg': 0,   'guifg': '#004022', 'guibg': '#000000'},
      \   'EndOfBuffer':  {'ctermfg': 22,  'ctermbg': 0,   'guifg': '#004022', 'guibg': '#000000'},
      \   'SignColumn':   {'ctermfg': 35,  'ctermbg': 0,   'guifg': '#00b25f', 'guibg': '#000000'},
      \   'Comment':      {'ctermfg': 22,  'ctermbg': 'NONE', 'guifg': '#00733d', 'guibg': 'NONE', 'cterm': 'italic', 'gui': 'italic'},
      \   'String':       {'ctermfg': 35,  'ctermbg': 233, 'guifg': '#00b25f', 'guibg': '#011f11'},
      \   'Number':       {'ctermfg': 41,  'ctermbg': 'NONE', 'guifg': '#00e57a', 'guibg': 'NONE'},
      \   'Keyword':      {'ctermfg': 41,  'ctermbg': 'NONE', 'guifg': '#00e57a', 'guibg': 'NONE'},
      \   'Statement':    {'ctermfg': 41,  'ctermbg': 'NONE', 'guifg': '#00e57a', 'guibg': 'NONE'},
      \   'Type':         {'ctermfg': 42,  'ctermbg': 'NONE', 'guifg': '#00cd6d', 'guibg': 'NONE'},
      \   'Function':     {'ctermfg': 48,  'ctermbg': 'NONE', 'guifg': '#00ff88', 'guibg': 'NONE'},
      \   'Identifier':   {'ctermfg': 35,  'ctermbg': 'NONE', 'guifg': '#00b25f', 'guibg': 'NONE'},
      \   'Operator':     {'ctermfg': 22,  'ctermbg': 'NONE', 'guifg': '#00733d', 'guibg': 'NONE'},
      \   'Special':      {'ctermfg': 42,  'ctermbg': 'NONE', 'guifg': '#00cd6d', 'guibg': 'NONE'},
      \   'PreProc':      {'ctermfg': 41,  'ctermbg': 'NONE', 'guifg': '#00e57a', 'guibg': 'NONE'},
      \   'Constant':     {'ctermfg': 41,  'ctermbg': 'NONE', 'guifg': '#00e57a', 'guibg': 'NONE'},
      \   'Todo':         {'ctermfg': 161, 'ctermbg': 52,  'guifg': '#cc0037', 'guibg': '#30000c', 'cterm': 'bold', 'gui': 'bold'},
      \   'Error':        {'ctermfg': 161, 'ctermbg': 0,   'guifg': '#cc0037', 'guibg': '#000000', 'cterm': 'bold', 'gui': 'bold'},
      \   'WarningMsg':   {'ctermfg': 32,  'ctermbg': 0,   'guifg': '#0081c7', 'guibg': '#000000'},
      \   'Directory':    {'ctermfg': 41,  'ctermbg': 'NONE', 'guifg': '#00e57a', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'Title':        {'ctermfg': 48,  'ctermbg': 'NONE', 'guifg': '#00ff88', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'MoreMsg':      {'ctermfg': 42,  'ctermbg': 'NONE', 'guifg': '#00cd6d', 'guibg': 'NONE'},
      \   'Question':     {'ctermfg': 42,  'ctermbg': 'NONE', 'guifg': '#00cd6d', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'Float':        {'ctermfg': 41,  'ctermbg': 'NONE', 'guifg': '#00e57a', 'guibg': 'NONE'},
      \   'Conditional':  {'ctermfg': 41,  'ctermbg': 'NONE', 'guifg': '#00e57a', 'guibg': 'NONE'},
      \   'Repeat':       {'ctermfg': 41,  'ctermbg': 'NONE', 'guifg': '#00e57a', 'guibg': 'NONE'},
      \ },
      \ 'finder': {
      \   'Normal':       {'ctermfg': 35,  'ctermbg': 0,   'guifg': '#00b25f', 'guibg': '#000000'},
      \   'Prompt':       {'ctermfg': 48,  'ctermbg': 0,   'guifg': '#00ff88', 'guibg': '#000000', 'cterm': 'bold', 'gui': 'bold'},
      \   'Status':       {'ctermfg': 22,  'ctermbg': 0,   'guifg': '#00733d', 'guibg': '#000000'},
      \   'Cursor':       {'ctermfg': 0,   'ctermbg': 41,  'guifg': '#000000', 'guibg': '#00e57a', 'cterm': 'bold', 'gui': 'bold'},
      \   'Selected':     {'ctermfg': 48,  'ctermbg': 233, 'guifg': '#00ff88', 'guibg': '#011f11', 'cterm': 'bold', 'gui': 'bold'},
      \   'Border':       {'ctermfg': 22,  'ctermbg': 0,   'guifg': '#004022', 'guibg': '#000000'},
      \   'Preview':      {'ctermfg': 35,  'ctermbg': 233, 'guifg': '#00b25f', 'guibg': '#01120a'},
      \   'PreviewTitle': {'ctermfg': 48,  'ctermbg': 233, 'guifg': '#00ff88', 'guibg': '#01120a', 'cterm': 'bold', 'gui': 'bold'},
      \ },
      \ 'statusline': {
      \   'mode_normal':  {'ctermfg': 0,   'ctermbg': 35,  'guifg': '#000000', 'guibg': '#00b25f'},
      \   'mode_insert':  {'ctermfg': 0,   'ctermbg': 48,  'guifg': '#000000', 'guibg': '#00ff88'},
      \   'mode_visual':  {'ctermfg': 0,   'ctermbg': 42,  'guifg': '#000000', 'guibg': '#00cd6d'},
      \   'mode_replace': {'ctermfg': 0,   'ctermbg': 161, 'guifg': '#000000', 'guibg': '#cc0037'},
      \   'mode_command': {'ctermfg': 0,   'ctermbg': 32,  'guifg': '#000000', 'guibg': '#0081c7'},
      \   'branch':       {'ctermfg': 41,  'ctermbg': 233, 'guifg': '#00e57a', 'guibg': '#01120a'},
      \   'file':         {'ctermfg': 35,  'ctermbg': 233, 'guifg': '#00b25f', 'guibg': '#011f11'},
      \   'info':         {'ctermfg': 22,  'ctermbg': 233, 'guifg': '#00733d', 'guibg': '#01120a'},
      \   'position':     {'ctermfg': 35,  'ctermbg': 233, 'guifg': '#00b25f', 'guibg': '#011f11'},
      \   'clock':        {'ctermfg': 22,  'ctermbg': 233, 'guifg': '#00733d', 'guibg': '#01120a'},
      \   'modified':     {'ctermfg': 161, 'ctermbg': 233, 'guifg': '#cc0037', 'guibg': '#01120a', 'cterm': 'bold', 'gui': 'bold'},
      \   'readonly':     {'ctermfg': 161, 'ctermbg': 233, 'guifg': '#cc0037', 'guibg': '#01120a', 'cterm': 'bold', 'gui': 'bold'},
      \ },
      \ }

" ---------------------------------------------------------------------------
" Resolve a theme by name (built-in or custom from disk)
" ---------------------------------------------------------------------------
function! neofinder#theme#get(name) abort
  if has_key(s:themes, a:name)
    return s:themes[a:name]
  endif
  " Try loading from ~/.neofinder/themes/<name>.vim
  let path = expand('~/.neofinder/themes/' . a:name . '.vim')
  if filereadable(path)
    try
      execute 'source ' . fnameescape(path)
      if exists('g:neofinder_custom_theme')
        let theme = deepcopy(g:neofinder_custom_theme)
        unlet g:neofinder_custom_theme
        return theme
      endif
    catch
    endtry
  endif
  return s:themes.matrix
endfunction

" ---------------------------------------------------------------------------
" List all available theme names
" ---------------------------------------------------------------------------
function! neofinder#theme#list() abort
  let names = keys(s:themes)
  let dir = expand('~/.neofinder/themes')
  if isdirectory(dir)
    for f in glob(dir . '/*.vim', 0, 1)
      let name = fnamemodify(f, ':t:r')
      if index(names, name) < 0
        call add(names, name)
      endif
    endfor
  endif
  return sort(names)
endfunction

" ---------------------------------------------------------------------------
" Apply a single highlight group
" ---------------------------------------------------------------------------
function! s:apply_hl(hlname, attrs) abort
  let cmd = 'highlight ' . a:hlname
  let cmd .= ' ctermfg=' . get(a:attrs, 'ctermfg', 'NONE')
  let cmd .= ' ctermbg=' . get(a:attrs, 'ctermbg', 'NONE')
  let cmd .= ' guifg='   . get(a:attrs, 'guifg',   'NONE')
  let cmd .= ' guibg='   . get(a:attrs, 'guibg',   'NONE')
  let cmd .= ' cterm='   . get(a:attrs, 'cterm',   'NONE')
  let cmd .= ' gui='     . get(a:attrs, 'gui',     'NONE')
  execute cmd
endfunction

" ---------------------------------------------------------------------------
" apply() -- apply theme globally: editor + finder + statusline
" ---------------------------------------------------------------------------
function! neofinder#theme#apply() abort
  let name = get(g:neofinder, 'theme', 'matrix')
  let theme = neofinder#theme#get(name)

  " 1) Apply GLOBAL editor highlights (affects all of Vim)
  if has_key(theme, 'editor')
    for [hlname, attrs] in items(theme.editor)
      call s:apply_hl(hlname, attrs)
    endfor
  endif

  " 2) Apply NeoFinder-specific UI highlights
  if has_key(theme, 'finder')
    let finder_map = {
          \ 'Normal':       'NeoFinderNormal',
          \ 'Prompt':       'NeoFinderPrompt',
          \ 'Status':       'NeoFinderStatus',
          \ 'Cursor':       'NeoFinderCursor',
          \ 'Selected':     'NeoFinderSelected',
          \ 'Border':       'NeoFinderBorder',
          \ 'Preview':      'NeoFinderPreview',
          \ 'PreviewTitle': 'NeoFinderPreviewTitle',
          \ }
    for [key, hlname] in items(finder_map)
      if has_key(theme.finder, key)
        call s:apply_hl(hlname, theme.finder[key])
      endif
    endfor
  endif

  " 3) Apply statusline highlight groups
  if has_key(theme, 'statusline')
    let sl_map = {
          \ 'mode_normal':  'NeoStMode',
          \ 'mode_insert':  'NeoStModeInsert',
          \ 'mode_visual':  'NeoStModeVisual',
          \ 'mode_replace': 'NeoStModeReplace',
          \ 'mode_command': 'NeoStModeCommand',
          \ 'branch':       'NeoStBranch',
          \ 'file':         'NeoStFile',
          \ 'info':         'NeoStInfo',
          \ 'position':     'NeoStPosition',
          \ 'clock':        'NeoStClock',
          \ 'modified':     'NeoStModified',
          \ 'readonly':     'NeoStReadonly',
          \ }
    for [key, hlname] in items(sl_map)
      if has_key(theme.statusline, key)
        call s:apply_hl(hlname, theme.statusline[key])
      endif
    endfor
  endif

  " 4) Apply preview syntax highlight groups (for syntax in preview pane)
  "    These mirror the editor syntax groups but as NeoFinder-prefixed groups
  "    so preview.vim can link to them without clobbering the user's colorscheme.
  if has_key(theme, 'editor')
    let syntax_map = {
          \ 'Keyword':  'NeoFinderKeyword',
          \ 'String':   'NeoFinderString',
          \ 'Comment':  'NeoFinderComment',
          \ 'Number':   'NeoFinderNumber',
          \ 'Type':     'NeoFinderType',
          \ 'Function': 'NeoFinderFunction',
          \ 'Operator': 'NeoFinderOperator',
          \ 'Special':  'NeoFinderSpecial',
          \ }
    for [key, hlname] in items(syntax_map)
      if has_key(theme.editor, key)
        call s:apply_hl(hlname, theme.editor[key])
      endif
    endfor
  endif

  " 5) Enable the global custom statusline
  call neofinder#statusline#enable()
endfunction

" ---------------------------------------------------------------------------
" apply_editor_only() -- apply just editor colors without statusline
"   (for use during NeoConfig panel)
" ---------------------------------------------------------------------------
function! neofinder#theme#apply_editor_only() abort
  let name = get(g:neofinder, 'theme', 'matrix')
  let theme = neofinder#theme#get(name)
  if has_key(theme, 'editor')
    for [hlname, attrs] in items(theme.editor)
      call s:apply_hl(hlname, attrs)
    endfor
  endif
endfunction

" ---------------------------------------------------------------------------
" set_buffer_highlights() -- NeoFinder buffer winhighlight
" ---------------------------------------------------------------------------
function! neofinder#theme#set_buffer_highlights() abort
  if exists('+winhighlight')
    setlocal winhighlight=Normal:NeoFinderNormal,CursorLine:NeoFinderCursor,EndOfBuffer:NeoFinderNormal
  endif
endfunction

" ---------------------------------------------------------------------------
" set_preview_highlights() -- preview buffer winhighlight + syntax links
" ---------------------------------------------------------------------------
function! neofinder#theme#set_preview_highlights() abort
  if exists('+winhighlight')
    setlocal winhighlight=Normal:NeoFinderPreview,EndOfBuffer:NeoFinderPreview
  endif
  " These only affect the preview window (restored when it closes)
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
" Save / register custom themes
" ---------------------------------------------------------------------------
function! neofinder#theme#save(name, theme_dict) abort
  let dir = expand('~/.neofinder/themes')
  if !isdirectory(dir)
    call mkdir(dir, 'p', 0700)
  endif
  let path = dir . '/' . a:name . '.vim'
  let lines = ['" NeoFinder custom theme: ' . a:name,
        \ '" Auto-generated -- edit freely',
        \ '" Structure: { "editor": {...}, "finder": {...}, "statusline": {...} }',
        \ '',
        \ 'let g:neofinder_custom_theme = {']
  for [section, sdict] in items(a:theme_dict)
    call add(lines, printf("      \\ '%s': {", section))
    for [key, attrs] in items(sdict)
      let parts = []
      for [ak, av] in items(attrs)
        if type(av) == type(0)
          call add(parts, printf("'%s': %d", ak, av))
        else
          call add(parts, printf("'%s': '%s'", ak, av))
        endif
      endfor
      call add(lines, printf("      \\   '%s': {%s},", key, join(parts, ', ')))
    endfor
    call add(lines, '      \ },')
  endfor
  call add(lines, '      \ }')
  call writefile(lines, path)
  return path
endfunction

function! neofinder#theme#register(name, theme_dict) abort
  let s:themes[a:name] = a:theme_dict
endfunction

" ---------------------------------------------------------------------------
" switch({name}) -- switch theme globally.  Empty arg lists available themes.
" ---------------------------------------------------------------------------
function! neofinder#theme#switch(name) abort
  if a:name ==# ''
    echo '  Available themes: ' . join(neofinder#theme#list(), ', ')
    echo '  Active: ' . get(g:neofinder, 'theme', 'matrix')
    echo '  Usage: :NeoTheme <name>'
    return
  endif
  let g:neofinder.theme = a:name
  call neofinder#theme#apply()
  echo '  Theme switched to: ' . a:name
endfunction
