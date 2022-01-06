" Copyright (c) 2022 zhongzhong

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

