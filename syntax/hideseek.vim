" Copyright (c) 2022 zhongzhong
if exists("b:current_syntax")
  finish
endif

syntax clear
syntax match hideseekTitle /^[A-Za-z-]*/ contained
syntax match hideseekTitleColon /^[A-Za-z-]*:/ contains=hideseekTitle
syntax match hideseekReg /^ ./ contained
syntax match hideseekRegColon /^ .:/ contains=hideseekReg
highlight default link hideseekTitle Title
highlight default link hideseekTitleColon NonText
highlight default link hideseekReg Label
highlight default link hideseekRegColon NonText
highlight default link hideseekSelected Todo
" setlocal nonumber buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap
"   \ modifiable statusline=>\ Buffers nocursorline nofoldenable


" unlet b:current_syntax

let b:current_syntax = "hideseek"   
setlocal nobuflisted nonumber norelativenumber statusline=\ Buffers
