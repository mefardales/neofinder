" neofinder#theme  -- Matrix cyberpunk color scheme
"
" Pure green (#00FF41 / #00CC00) on black (#000000).
" Provides highlight groups used by the finder buffer and preview window.

" ---------------------------------------------------------------------------
" apply() -- called once when the finder opens
" ---------------------------------------------------------------------------
function! neofinder#theme#apply() abort
  let theme = get(g:neofinder, 'theme', 'matrix')
  if theme !=# 'matrix'
    return
  endif

  " Core highlight groups
  highlight NeoFinderNormal    ctermfg=46  ctermbg=0  guifg=#00FF41 guibg=#000000
  highlight NeoFinderPrompt    ctermfg=46  ctermbg=0  guifg=#00FF41 guibg=#0A0A0A cterm=bold gui=bold
  highlight NeoFinderStatus    ctermfg=34  ctermbg=0  guifg=#00CC00 guibg=#0A0A0A
  highlight NeoFinderCursor    ctermfg=0   ctermbg=46 guifg=#000000 guibg=#00FF41 cterm=bold gui=bold
  highlight NeoFinderSelected  ctermfg=82  ctermbg=22 guifg=#55FF55 guibg=#003300 cterm=bold gui=bold
  highlight NeoFinderBorder    ctermfg=28  ctermbg=0  guifg=#008800 guibg=#000000

  " Preview highlight groups (Matrix-friendly syntax)
  highlight NeoFinderPreview      ctermfg=46  ctermbg=0  guifg=#00FF41 guibg=#0A0A0A
  highlight NeoFinderPreviewTitle ctermfg=46  ctermbg=0  guifg=#00FF41 guibg=#0A0A0A cterm=bold gui=bold

  " Syntax-aware preview colors -- all green family
  highlight NeoFinderKeyword   ctermfg=46  ctermbg=0  guifg=#00FF41 guibg=#0A0A0A cterm=bold gui=bold
  highlight NeoFinderString    ctermfg=34  ctermbg=0  guifg=#00CC00 guibg=#0A0A0A
  highlight NeoFinderComment   ctermfg=22  ctermbg=0  guifg=#006600 guibg=#0A0A0A cterm=italic gui=italic
  highlight NeoFinderNumber    ctermfg=48  ctermbg=0  guifg=#00FF99 guibg=#0A0A0A
  highlight NeoFinderType      ctermfg=40  ctermbg=0  guifg=#00DD33 guibg=#0A0A0A
  highlight NeoFinderFunction  ctermfg=82  ctermbg=0  guifg=#55FF55 guibg=#0A0A0A cterm=bold gui=bold
  highlight NeoFinderOperator  ctermfg=28  ctermbg=0  guifg=#008800 guibg=#0A0A0A
  highlight NeoFinderSpecial   ctermfg=48  ctermbg=0  guifg=#00FF99 guibg=#0A0A0A cterm=bold gui=bold
endfunction

" ---------------------------------------------------------------------------
" set_buffer_highlights() -- link groups for the finder buffer
" ---------------------------------------------------------------------------
function! neofinder#theme#set_buffer_highlights() abort
  let theme = get(g:neofinder, 'theme', 'matrix')
  if theme !=# 'matrix'
    return
  endif

  setlocal winhighlight=Normal:NeoFinderNormal,CursorLine:NeoFinderCursor,EndOfBuffer:NeoFinderNormal
  " Fallback for Vim without winhighlight
  if !exists('+winhighlight')
    highlight link Normal NeoFinderNormal
  endif
endfunction

" ---------------------------------------------------------------------------
" set_preview_highlights() -- link groups for the preview buffer
" ---------------------------------------------------------------------------
function! neofinder#theme#set_preview_highlights() abort
  let theme = get(g:neofinder, 'theme', 'matrix')
  if theme !=# 'matrix'
    return
  endif

  setlocal winhighlight=Normal:NeoFinderPreview,EndOfBuffer:NeoFinderPreview

  " Link standard syntax groups to our Matrix variants
  highlight! link Comment    NeoFinderComment
  highlight! link String     NeoFinderString
  highlight! link Number     NeoFinderNumber
  highlight! link Float      NeoFinderNumber
  highlight! link Keyword    NeoFinderKeyword
  highlight! link Statement  NeoFinderKeyword
  highlight! link Conditional NeoFinderKeyword
  highlight! link Repeat     NeoFinderKeyword
  highlight! link Type       NeoFinderType
  highlight! link Function   NeoFinderFunction
  highlight! link Identifier NeoFinderFunction
  highlight! link Operator   NeoFinderOperator
  highlight! link Special    NeoFinderSpecial
  highlight! link PreProc    NeoFinderSpecial
  highlight! link Constant   NeoFinderNumber
  highlight! link Todo       NeoFinderSelected
endfunction
