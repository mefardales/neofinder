" neofinder#theme  -- Global + NeoFinder multi-theme system
"
" Themes affect the ENTIRE Vim editor: Normal, StatusLine, CursorLine,
" LineNr, Visual, Pmenu, syntax groups, etc.  Not just NeoFinder windows.
"
" Built-in themes: matrix, dark, cyberpunk, default
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
let s:themes.matrix = {
      \ 'editor': {
      \   'Normal':       {'ctermfg': 46,  'ctermbg': 0,   'guifg': '#00FF41', 'guibg': '#000000'},
      \   'StatusLine':   {'ctermfg': 0,   'ctermbg': 46,  'guifg': '#000000', 'guibg': '#00FF41', 'cterm': 'bold', 'gui': 'bold'},
      \   'StatusLineNC': {'ctermfg': 0,   'ctermbg': 22,  'guifg': '#003300', 'guibg': '#006600'},
      \   'CursorLine':   {'ctermfg': 'NONE', 'ctermbg': 234, 'guifg': 'NONE', 'guibg': '#0D0D0D'},
      \   'CursorLineNr': {'ctermfg': 46,  'ctermbg': 234, 'guifg': '#00FF41', 'guibg': '#0D0D0D', 'cterm': 'bold', 'gui': 'bold'},
      \   'LineNr':       {'ctermfg': 22,  'ctermbg': 0,   'guifg': '#005500', 'guibg': '#000000'},
      \   'Visual':       {'ctermfg': 0,   'ctermbg': 34,  'guifg': '#000000', 'guibg': '#00AA00'},
      \   'VertSplit':    {'ctermfg': 22,  'ctermbg': 0,   'guifg': '#006600', 'guibg': '#000000'},
      \   'Pmenu':        {'ctermfg': 46,  'ctermbg': 233, 'guifg': '#00FF41', 'guibg': '#0A0A0A'},
      \   'PmenuSel':     {'ctermfg': 0,   'ctermbg': 46,  'guifg': '#000000', 'guibg': '#00FF41', 'cterm': 'bold', 'gui': 'bold'},
      \   'PmenuSbar':    {'ctermfg': 'NONE', 'ctermbg': 233, 'guifg': 'NONE', 'guibg': '#0A0A0A'},
      \   'PmenuThumb':   {'ctermfg': 'NONE', 'ctermbg': 22,  'guifg': 'NONE', 'guibg': '#006600'},
      \   'TabLine':      {'ctermfg': 34,  'ctermbg': 233, 'guifg': '#00AA00', 'guibg': '#0A0A0A'},
      \   'TabLineSel':   {'ctermfg': 0,   'ctermbg': 46,  'guifg': '#000000', 'guibg': '#00FF41', 'cterm': 'bold', 'gui': 'bold'},
      \   'TabLineFill':  {'ctermfg': 22,  'ctermbg': 233, 'guifg': '#006600', 'guibg': '#0A0A0A'},
      \   'Search':       {'ctermfg': 0,   'ctermbg': 82,  'guifg': '#000000', 'guibg': '#55FF00'},
      \   'IncSearch':    {'ctermfg': 0,   'ctermbg': 46,  'guifg': '#000000', 'guibg': '#00FF41', 'cterm': 'bold', 'gui': 'bold'},
      \   'MatchParen':   {'ctermfg': 0,   'ctermbg': 34,  'guifg': '#000000', 'guibg': '#00AA00', 'cterm': 'bold', 'gui': 'bold'},
      \   'NonText':      {'ctermfg': 22,  'ctermbg': 0,   'guifg': '#003300', 'guibg': '#000000'},
      \   'EndOfBuffer':  {'ctermfg': 22,  'ctermbg': 0,   'guifg': '#003300', 'guibg': '#000000'},
      \   'SignColumn':   {'ctermfg': 46,  'ctermbg': 0,   'guifg': '#00FF41', 'guibg': '#000000'},
      \   'Comment':      {'ctermfg': 22,  'ctermbg': 'NONE', 'guifg': '#006600', 'guibg': 'NONE', 'cterm': 'italic', 'gui': 'italic'},
      \   'String':       {'ctermfg': 34,  'ctermbg': 'NONE', 'guifg': '#00CC00', 'guibg': 'NONE'},
      \   'Number':       {'ctermfg': 48,  'ctermbg': 'NONE', 'guifg': '#00FF99', 'guibg': 'NONE'},
      \   'Keyword':      {'ctermfg': 46,  'ctermbg': 'NONE', 'guifg': '#00FF41', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'Statement':    {'ctermfg': 46,  'ctermbg': 'NONE', 'guifg': '#00FF41', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'Type':         {'ctermfg': 40,  'ctermbg': 'NONE', 'guifg': '#00DD33', 'guibg': 'NONE'},
      \   'Function':     {'ctermfg': 82,  'ctermbg': 'NONE', 'guifg': '#55FF55', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'Identifier':   {'ctermfg': 82,  'ctermbg': 'NONE', 'guifg': '#55FF55', 'guibg': 'NONE'},
      \   'Operator':     {'ctermfg': 28,  'ctermbg': 'NONE', 'guifg': '#008800', 'guibg': 'NONE'},
      \   'Special':      {'ctermfg': 48,  'ctermbg': 'NONE', 'guifg': '#00FF99', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'PreProc':      {'ctermfg': 48,  'ctermbg': 'NONE', 'guifg': '#00FF99', 'guibg': 'NONE'},
      \   'Constant':     {'ctermfg': 48,  'ctermbg': 'NONE', 'guifg': '#00FF99', 'guibg': 'NONE'},
      \   'Todo':         {'ctermfg': 0,   'ctermbg': 46,  'guifg': '#000000', 'guibg': '#00FF41', 'cterm': 'bold', 'gui': 'bold'},
      \   'Error':        {'ctermfg': 196, 'ctermbg': 0,   'guifg': '#FF0000', 'guibg': '#000000', 'cterm': 'bold', 'gui': 'bold'},
      \   'WarningMsg':   {'ctermfg': 226, 'ctermbg': 0,   'guifg': '#FFFF00', 'guibg': '#000000'},
      \   'Directory':    {'ctermfg': 46,  'ctermbg': 'NONE', 'guifg': '#00FF41', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'Title':        {'ctermfg': 46,  'ctermbg': 'NONE', 'guifg': '#00FF41', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'MoreMsg':      {'ctermfg': 46,  'ctermbg': 'NONE', 'guifg': '#00FF41', 'guibg': 'NONE'},
      \   'Question':     {'ctermfg': 46,  'ctermbg': 'NONE', 'guifg': '#00FF41', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'Float':        {'ctermfg': 48,  'ctermbg': 'NONE', 'guifg': '#00FF99', 'guibg': 'NONE'},
      \   'Conditional':  {'ctermfg': 46,  'ctermbg': 'NONE', 'guifg': '#00FF41', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'Repeat':       {'ctermfg': 46,  'ctermbg': 'NONE', 'guifg': '#00FF41', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \ },
      \ 'finder': {
      \   'Normal':       {'ctermfg': 46,  'ctermbg': 0,   'guifg': '#00FF41', 'guibg': '#000000'},
      \   'Prompt':       {'ctermfg': 46,  'ctermbg': 0,   'guifg': '#00FF41', 'guibg': '#0A0A0A', 'cterm': 'bold', 'gui': 'bold'},
      \   'Status':       {'ctermfg': 34,  'ctermbg': 0,   'guifg': '#00CC00', 'guibg': '#0A0A0A'},
      \   'Cursor':       {'ctermfg': 0,   'ctermbg': 46,  'guifg': '#000000', 'guibg': '#00FF41', 'cterm': 'bold', 'gui': 'bold'},
      \   'Selected':     {'ctermfg': 82,  'ctermbg': 22,  'guifg': '#55FF55', 'guibg': '#003300', 'cterm': 'bold', 'gui': 'bold'},
      \   'Border':       {'ctermfg': 28,  'ctermbg': 0,   'guifg': '#008800', 'guibg': '#000000'},
      \   'Preview':      {'ctermfg': 46,  'ctermbg': 0,   'guifg': '#00FF41', 'guibg': '#0A0A0A'},
      \   'PreviewTitle': {'ctermfg': 46,  'ctermbg': 0,   'guifg': '#00FF41', 'guibg': '#0A0A0A', 'cterm': 'bold', 'gui': 'bold'},
      \ },
      \ 'statusline': {
      \   'mode_normal':  {'ctermfg': 0,  'ctermbg': 46,  'guifg': '#000000', 'guibg': '#00FF41'},
      \   'mode_insert':  {'ctermfg': 0,  'ctermbg': 82,  'guifg': '#000000', 'guibg': '#55FF00'},
      \   'mode_visual':  {'ctermfg': 0,  'ctermbg': 34,  'guifg': '#000000', 'guibg': '#00AA00'},
      \   'mode_replace': {'ctermfg': 0,  'ctermbg': 196, 'guifg': '#000000', 'guibg': '#FF0000'},
      \   'mode_command': {'ctermfg': 0,  'ctermbg': 226, 'guifg': '#000000', 'guibg': '#FFFF00'},
      \   'branch':       {'ctermfg': 46, 'ctermbg': 233, 'guifg': '#00FF41', 'guibg': '#0A0A0A'},
      \   'file':         {'ctermfg': 46, 'ctermbg': 234, 'guifg': '#00FF41', 'guibg': '#111111'},
      \   'info':         {'ctermfg': 34, 'ctermbg': 233, 'guifg': '#00AA00', 'guibg': '#0A0A0A'},
      \   'position':     {'ctermfg': 46, 'ctermbg': 234, 'guifg': '#00FF41', 'guibg': '#111111'},
      \   'clock':        {'ctermfg': 34, 'ctermbg': 233, 'guifg': '#00AA00', 'guibg': '#0A0A0A'},
      \   'modified':     {'ctermfg': 226, 'ctermbg': 233, 'guifg': '#FFFF00', 'guibg': '#0A0A0A', 'cterm': 'bold', 'gui': 'bold'},
      \   'readonly':     {'ctermfg': 196, 'ctermbg': 233, 'guifg': '#FF0000', 'guibg': '#0A0A0A', 'cterm': 'bold', 'gui': 'bold'},
      \ },
      \ }

" ===== DARK =====
let s:themes.dark = {
      \ 'editor': {
      \   'Normal':       {'ctermfg': 250, 'ctermbg': 234, 'guifg': '#BCBCBC', 'guibg': '#1C1C1C'},
      \   'StatusLine':   {'ctermfg': 255, 'ctermbg': 236, 'guifg': '#EEEEEE', 'guibg': '#303030', 'cterm': 'bold', 'gui': 'bold'},
      \   'StatusLineNC': {'ctermfg': 245, 'ctermbg': 235, 'guifg': '#8A8A8A', 'guibg': '#262626'},
      \   'CursorLine':   {'ctermfg': 'NONE', 'ctermbg': 236, 'guifg': 'NONE', 'guibg': '#303030'},
      \   'CursorLineNr': {'ctermfg': 75,  'ctermbg': 236, 'guifg': '#5FAFFF', 'guibg': '#303030', 'cterm': 'bold', 'gui': 'bold'},
      \   'LineNr':       {'ctermfg': 240, 'ctermbg': 234, 'guifg': '#585858', 'guibg': '#1C1C1C'},
      \   'Visual':       {'ctermfg': 'NONE', 'ctermbg': 238, 'guifg': 'NONE', 'guibg': '#444444'},
      \   'VertSplit':    {'ctermfg': 238, 'ctermbg': 234, 'guifg': '#444444', 'guibg': '#1C1C1C'},
      \   'Pmenu':        {'ctermfg': 250, 'ctermbg': 236, 'guifg': '#BCBCBC', 'guibg': '#303030'},
      \   'PmenuSel':     {'ctermfg': 234, 'ctermbg': 75,  'guifg': '#1C1C1C', 'guibg': '#5FAFFF', 'cterm': 'bold', 'gui': 'bold'},
      \   'PmenuSbar':    {'ctermfg': 'NONE', 'ctermbg': 236, 'guifg': 'NONE', 'guibg': '#303030'},
      \   'PmenuThumb':   {'ctermfg': 'NONE', 'ctermbg': 240, 'guifg': 'NONE', 'guibg': '#585858'},
      \   'TabLine':      {'ctermfg': 245, 'ctermbg': 235, 'guifg': '#8A8A8A', 'guibg': '#262626'},
      \   'TabLineSel':   {'ctermfg': 255, 'ctermbg': 238, 'guifg': '#EEEEEE', 'guibg': '#444444', 'cterm': 'bold', 'gui': 'bold'},
      \   'TabLineFill':  {'ctermfg': 240, 'ctermbg': 235, 'guifg': '#585858', 'guibg': '#262626'},
      \   'Search':       {'ctermfg': 234, 'ctermbg': 215, 'guifg': '#1C1C1C', 'guibg': '#FFAF5F'},
      \   'IncSearch':    {'ctermfg': 234, 'ctermbg': 75,  'guifg': '#1C1C1C', 'guibg': '#5FAFFF', 'cterm': 'bold', 'gui': 'bold'},
      \   'MatchParen':   {'ctermfg': 234, 'ctermbg': 75,  'guifg': '#1C1C1C', 'guibg': '#5FAFFF', 'cterm': 'bold', 'gui': 'bold'},
      \   'NonText':      {'ctermfg': 238, 'ctermbg': 234, 'guifg': '#444444', 'guibg': '#1C1C1C'},
      \   'EndOfBuffer':  {'ctermfg': 238, 'ctermbg': 234, 'guifg': '#444444', 'guibg': '#1C1C1C'},
      \   'SignColumn':   {'ctermfg': 250, 'ctermbg': 234, 'guifg': '#BCBCBC', 'guibg': '#1C1C1C'},
      \   'Comment':      {'ctermfg': 242, 'ctermbg': 'NONE', 'guifg': '#6C6C6C', 'guibg': 'NONE', 'cterm': 'italic', 'gui': 'italic'},
      \   'String':       {'ctermfg': 108, 'ctermbg': 'NONE', 'guifg': '#87AF87', 'guibg': 'NONE'},
      \   'Number':       {'ctermfg': 173, 'ctermbg': 'NONE', 'guifg': '#D7875F', 'guibg': 'NONE'},
      \   'Keyword':      {'ctermfg': 168, 'ctermbg': 'NONE', 'guifg': '#D75F87', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'Statement':    {'ctermfg': 168, 'ctermbg': 'NONE', 'guifg': '#D75F87', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'Type':         {'ctermfg': 110, 'ctermbg': 'NONE', 'guifg': '#87AFD7', 'guibg': 'NONE'},
      \   'Function':     {'ctermfg': 75,  'ctermbg': 'NONE', 'guifg': '#5FAFFF', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'Identifier':   {'ctermfg': 75,  'ctermbg': 'NONE', 'guifg': '#5FAFFF', 'guibg': 'NONE'},
      \   'Operator':     {'ctermfg': 250, 'ctermbg': 'NONE', 'guifg': '#BCBCBC', 'guibg': 'NONE'},
      \   'Special':      {'ctermfg': 215, 'ctermbg': 'NONE', 'guifg': '#FFAF5F', 'guibg': 'NONE'},
      \   'PreProc':      {'ctermfg': 215, 'ctermbg': 'NONE', 'guifg': '#FFAF5F', 'guibg': 'NONE'},
      \   'Constant':     {'ctermfg': 173, 'ctermbg': 'NONE', 'guifg': '#D7875F', 'guibg': 'NONE'},
      \   'Todo':         {'ctermfg': 234, 'ctermbg': 215, 'guifg': '#1C1C1C', 'guibg': '#FFAF5F', 'cterm': 'bold', 'gui': 'bold'},
      \   'Error':        {'ctermfg': 196, 'ctermbg': 234, 'guifg': '#FF0000', 'guibg': '#1C1C1C', 'cterm': 'bold', 'gui': 'bold'},
      \   'WarningMsg':   {'ctermfg': 214, 'ctermbg': 234, 'guifg': '#FFAF00', 'guibg': '#1C1C1C'},
      \   'Directory':    {'ctermfg': 75,  'ctermbg': 'NONE', 'guifg': '#5FAFFF', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'Title':        {'ctermfg': 75,  'ctermbg': 'NONE', 'guifg': '#5FAFFF', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'MoreMsg':      {'ctermfg': 75,  'ctermbg': 'NONE', 'guifg': '#5FAFFF', 'guibg': 'NONE'},
      \   'Question':     {'ctermfg': 75,  'ctermbg': 'NONE', 'guifg': '#5FAFFF', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'Float':        {'ctermfg': 173, 'ctermbg': 'NONE', 'guifg': '#D7875F', 'guibg': 'NONE'},
      \   'Conditional':  {'ctermfg': 168, 'ctermbg': 'NONE', 'guifg': '#D75F87', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'Repeat':       {'ctermfg': 168, 'ctermbg': 'NONE', 'guifg': '#D75F87', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \ },
      \ 'finder': {
      \   'Normal':       {'ctermfg': 250, 'ctermbg': 234, 'guifg': '#BCBCBC', 'guibg': '#1C1C1C'},
      \   'Prompt':       {'ctermfg': 255, 'ctermbg': 234, 'guifg': '#EEEEEE', 'guibg': '#1C1C1C', 'cterm': 'bold', 'gui': 'bold'},
      \   'Status':       {'ctermfg': 245, 'ctermbg': 235, 'guifg': '#8A8A8A', 'guibg': '#262626'},
      \   'Cursor':       {'ctermfg': 234, 'ctermbg': 75,  'guifg': '#1C1C1C', 'guibg': '#5FAFFF', 'cterm': 'bold', 'gui': 'bold'},
      \   'Selected':     {'ctermfg': 117, 'ctermbg': 237, 'guifg': '#87D7FF', 'guibg': '#3A3A3A', 'cterm': 'bold', 'gui': 'bold'},
      \   'Border':       {'ctermfg': 240, 'ctermbg': 234, 'guifg': '#585858', 'guibg': '#1C1C1C'},
      \   'Preview':      {'ctermfg': 250, 'ctermbg': 235, 'guifg': '#BCBCBC', 'guibg': '#262626'},
      \   'PreviewTitle': {'ctermfg': 75,  'ctermbg': 235, 'guifg': '#5FAFFF', 'guibg': '#262626', 'cterm': 'bold', 'gui': 'bold'},
      \ },
      \ 'statusline': {
      \   'mode_normal':  {'ctermfg': 234, 'ctermbg': 75,  'guifg': '#1C1C1C', 'guibg': '#5FAFFF'},
      \   'mode_insert':  {'ctermfg': 234, 'ctermbg': 108, 'guifg': '#1C1C1C', 'guibg': '#87AF87'},
      \   'mode_visual':  {'ctermfg': 234, 'ctermbg': 215, 'guifg': '#1C1C1C', 'guibg': '#FFAF5F'},
      \   'mode_replace': {'ctermfg': 234, 'ctermbg': 196, 'guifg': '#1C1C1C', 'guibg': '#FF0000'},
      \   'mode_command': {'ctermfg': 234, 'ctermbg': 173, 'guifg': '#1C1C1C', 'guibg': '#D7875F'},
      \   'branch':       {'ctermfg': 75,  'ctermbg': 236, 'guifg': '#5FAFFF', 'guibg': '#303030'},
      \   'file':         {'ctermfg': 255, 'ctermbg': 237, 'guifg': '#EEEEEE', 'guibg': '#3A3A3A'},
      \   'info':         {'ctermfg': 245, 'ctermbg': 235, 'guifg': '#8A8A8A', 'guibg': '#262626'},
      \   'position':     {'ctermfg': 250, 'ctermbg': 236, 'guifg': '#BCBCBC', 'guibg': '#303030'},
      \   'clock':        {'ctermfg': 245, 'ctermbg': 235, 'guifg': '#8A8A8A', 'guibg': '#262626'},
      \   'modified':     {'ctermfg': 214, 'ctermbg': 236, 'guifg': '#FFAF00', 'guibg': '#303030', 'cterm': 'bold', 'gui': 'bold'},
      \   'readonly':     {'ctermfg': 196, 'ctermbg': 236, 'guifg': '#FF0000', 'guibg': '#303030', 'cterm': 'bold', 'gui': 'bold'},
      \ },
      \ }

" ===== CYBERPUNK =====
let s:themes.cyberpunk = {
      \ 'editor': {
      \   'Normal':       {'ctermfg': 201, 'ctermbg': 233, 'guifg': '#FF00FF', 'guibg': '#121212'},
      \   'StatusLine':   {'ctermfg': 0,   'ctermbg': 51,  'guifg': '#000000', 'guibg': '#00FFFF', 'cterm': 'bold', 'gui': 'bold'},
      \   'StatusLineNC': {'ctermfg': 233, 'ctermbg': 93,  'guifg': '#121212', 'guibg': '#8700FF'},
      \   'CursorLine':   {'ctermfg': 'NONE', 'ctermbg': 234, 'guifg': 'NONE', 'guibg': '#1C1C1C'},
      \   'CursorLineNr': {'ctermfg': 51,  'ctermbg': 234, 'guifg': '#00FFFF', 'guibg': '#1C1C1C', 'cterm': 'bold', 'gui': 'bold'},
      \   'LineNr':       {'ctermfg': 53,  'ctermbg': 233, 'guifg': '#5F005F', 'guibg': '#121212'},
      \   'Visual':       {'ctermfg': 0,   'ctermbg': 129, 'guifg': '#000000', 'guibg': '#AF00FF'},
      \   'VertSplit':    {'ctermfg': 129, 'ctermbg': 233, 'guifg': '#AF00FF', 'guibg': '#121212'},
      \   'Pmenu':        {'ctermfg': 201, 'ctermbg': 234, 'guifg': '#FF00FF', 'guibg': '#1C1C1C'},
      \   'PmenuSel':     {'ctermfg': 0,   'ctermbg': 51,  'guifg': '#000000', 'guibg': '#00FFFF', 'cterm': 'bold', 'gui': 'bold'},
      \   'PmenuSbar':    {'ctermfg': 'NONE', 'ctermbg': 234, 'guifg': 'NONE', 'guibg': '#1C1C1C'},
      \   'PmenuThumb':   {'ctermfg': 'NONE', 'ctermbg': 129, 'guifg': 'NONE', 'guibg': '#AF00FF'},
      \   'TabLine':      {'ctermfg': 129, 'ctermbg': 233, 'guifg': '#AF00FF', 'guibg': '#121212'},
      \   'TabLineSel':   {'ctermfg': 0,   'ctermbg': 51,  'guifg': '#000000', 'guibg': '#00FFFF', 'cterm': 'bold', 'gui': 'bold'},
      \   'TabLineFill':  {'ctermfg': 53,  'ctermbg': 233, 'guifg': '#5F005F', 'guibg': '#121212'},
      \   'Search':       {'ctermfg': 0,   'ctermbg': 226, 'guifg': '#000000', 'guibg': '#FFFF00'},
      \   'IncSearch':    {'ctermfg': 0,   'ctermbg': 51,  'guifg': '#000000', 'guibg': '#00FFFF', 'cterm': 'bold', 'gui': 'bold'},
      \   'MatchParen':   {'ctermfg': 0,   'ctermbg': 201, 'guifg': '#000000', 'guibg': '#FF00FF', 'cterm': 'bold', 'gui': 'bold'},
      \   'NonText':      {'ctermfg': 53,  'ctermbg': 233, 'guifg': '#5F005F', 'guibg': '#121212'},
      \   'EndOfBuffer':  {'ctermfg': 53,  'ctermbg': 233, 'guifg': '#5F005F', 'guibg': '#121212'},
      \   'SignColumn':   {'ctermfg': 201, 'ctermbg': 233, 'guifg': '#FF00FF', 'guibg': '#121212'},
      \   'Comment':      {'ctermfg': 240, 'ctermbg': 'NONE', 'guifg': '#585858', 'guibg': 'NONE', 'cterm': 'italic', 'gui': 'italic'},
      \   'String':       {'ctermfg': 207, 'ctermbg': 'NONE', 'guifg': '#FF5FFF', 'guibg': 'NONE'},
      \   'Number':       {'ctermfg': 214, 'ctermbg': 'NONE', 'guifg': '#FFAF00', 'guibg': 'NONE'},
      \   'Keyword':      {'ctermfg': 51,  'ctermbg': 'NONE', 'guifg': '#00FFFF', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'Statement':    {'ctermfg': 51,  'ctermbg': 'NONE', 'guifg': '#00FFFF', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'Type':         {'ctermfg': 129, 'ctermbg': 'NONE', 'guifg': '#AF00FF', 'guibg': 'NONE'},
      \   'Function':     {'ctermfg': 87,  'ctermbg': 'NONE', 'guifg': '#5FFFFF', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'Identifier':   {'ctermfg': 87,  'ctermbg': 'NONE', 'guifg': '#5FFFFF', 'guibg': 'NONE'},
      \   'Operator':     {'ctermfg': 201, 'ctermbg': 'NONE', 'guifg': '#FF00FF', 'guibg': 'NONE'},
      \   'Special':      {'ctermfg': 226, 'ctermbg': 'NONE', 'guifg': '#FFFF00', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'PreProc':      {'ctermfg': 226, 'ctermbg': 'NONE', 'guifg': '#FFFF00', 'guibg': 'NONE'},
      \   'Constant':     {'ctermfg': 214, 'ctermbg': 'NONE', 'guifg': '#FFAF00', 'guibg': 'NONE'},
      \   'Todo':         {'ctermfg': 0,   'ctermbg': 226, 'guifg': '#000000', 'guibg': '#FFFF00', 'cterm': 'bold', 'gui': 'bold'},
      \   'Error':        {'ctermfg': 196, 'ctermbg': 233, 'guifg': '#FF0000', 'guibg': '#121212', 'cterm': 'bold', 'gui': 'bold'},
      \   'WarningMsg':   {'ctermfg': 226, 'ctermbg': 233, 'guifg': '#FFFF00', 'guibg': '#121212'},
      \   'Directory':    {'ctermfg': 51,  'ctermbg': 'NONE', 'guifg': '#00FFFF', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'Title':        {'ctermfg': 51,  'ctermbg': 'NONE', 'guifg': '#00FFFF', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'MoreMsg':      {'ctermfg': 51,  'ctermbg': 'NONE', 'guifg': '#00FFFF', 'guibg': 'NONE'},
      \   'Question':     {'ctermfg': 51,  'ctermbg': 'NONE', 'guifg': '#00FFFF', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'Float':        {'ctermfg': 214, 'ctermbg': 'NONE', 'guifg': '#FFAF00', 'guibg': 'NONE'},
      \   'Conditional':  {'ctermfg': 51,  'ctermbg': 'NONE', 'guifg': '#00FFFF', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'Repeat':       {'ctermfg': 51,  'ctermbg': 'NONE', 'guifg': '#00FFFF', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \ },
      \ 'finder': {
      \   'Normal':       {'ctermfg': 201, 'ctermbg': 233, 'guifg': '#FF00FF', 'guibg': '#121212'},
      \   'Prompt':       {'ctermfg': 51,  'ctermbg': 233, 'guifg': '#00FFFF', 'guibg': '#121212', 'cterm': 'bold', 'gui': 'bold'},
      \   'Status':       {'ctermfg': 93,  'ctermbg': 233, 'guifg': '#8700FF', 'guibg': '#121212'},
      \   'Cursor':       {'ctermfg': 0,   'ctermbg': 51,  'guifg': '#000000', 'guibg': '#00FFFF', 'cterm': 'bold', 'gui': 'bold'},
      \   'Selected':     {'ctermfg': 218, 'ctermbg': 53,  'guifg': '#FFAFD7', 'guibg': '#5F005F', 'cterm': 'bold', 'gui': 'bold'},
      \   'Border':       {'ctermfg': 129, 'ctermbg': 233, 'guifg': '#AF00FF', 'guibg': '#121212'},
      \   'Preview':      {'ctermfg': 201, 'ctermbg': 234, 'guifg': '#FF00FF', 'guibg': '#1C1C1C'},
      \   'PreviewTitle': {'ctermfg': 51,  'ctermbg': 234, 'guifg': '#00FFFF', 'guibg': '#1C1C1C', 'cterm': 'bold', 'gui': 'bold'},
      \ },
      \ 'statusline': {
      \   'mode_normal':  {'ctermfg': 0,  'ctermbg': 51,  'guifg': '#000000', 'guibg': '#00FFFF'},
      \   'mode_insert':  {'ctermfg': 0,  'ctermbg': 201, 'guifg': '#000000', 'guibg': '#FF00FF'},
      \   'mode_visual':  {'ctermfg': 0,  'ctermbg': 129, 'guifg': '#000000', 'guibg': '#AF00FF'},
      \   'mode_replace': {'ctermfg': 0,  'ctermbg': 196, 'guifg': '#000000', 'guibg': '#FF0000'},
      \   'mode_command': {'ctermfg': 0,  'ctermbg': 226, 'guifg': '#000000', 'guibg': '#FFFF00'},
      \   'branch':       {'ctermfg': 51, 'ctermbg': 234, 'guifg': '#00FFFF', 'guibg': '#1C1C1C'},
      \   'file':         {'ctermfg': 201, 'ctermbg': 234, 'guifg': '#FF00FF', 'guibg': '#1C1C1C'},
      \   'info':         {'ctermfg': 129, 'ctermbg': 233, 'guifg': '#AF00FF', 'guibg': '#121212'},
      \   'position':     {'ctermfg': 51,  'ctermbg': 234, 'guifg': '#00FFFF', 'guibg': '#1C1C1C'},
      \   'clock':        {'ctermfg': 129, 'ctermbg': 233, 'guifg': '#AF00FF', 'guibg': '#121212'},
      \   'modified':     {'ctermfg': 226, 'ctermbg': 234, 'guifg': '#FFFF00', 'guibg': '#1C1C1C', 'cterm': 'bold', 'gui': 'bold'},
      \   'readonly':     {'ctermfg': 196, 'ctermbg': 234, 'guifg': '#FF0000', 'guibg': '#1C1C1C', 'cterm': 'bold', 'gui': 'bold'},
      \ },
      \ }

" ===== DEFAULT -- restore Vim native, no editor overrides =====
let s:themes.default = {
      \ 'editor': {},
      \ 'finder': {
      \   'Normal':       {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE'},
      \   'Prompt':       {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'Status':       {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE'},
      \   'Cursor':       {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE', 'cterm': 'reverse', 'gui': 'reverse'},
      \   'Selected':     {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'Border':       {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE'},
      \   'Preview':      {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE'},
      \   'PreviewTitle': {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \ },
      \ 'statusline': {
      \   'mode_normal':  {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'mode_insert':  {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'mode_visual':  {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'mode_replace': {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'mode_command': {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'branch':       {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE'},
      \   'file':         {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE'},
      \   'info':         {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE'},
      \   'position':     {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE'},
      \   'clock':        {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE'},
      \   'modified':     {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
      \   'readonly':     {'ctermfg': 'NONE', 'ctermbg': 'NONE', 'guifg': 'NONE', 'guibg': 'NONE', 'cterm': 'bold', 'gui': 'bold'},
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

  " 4) Enable the global custom statusline
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
