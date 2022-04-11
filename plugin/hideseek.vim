" Copyright (c) 2022 zhongzhong
" attention  
" filter function will change the firser parameter. should copy it and pass it
" exists function the parameter is String
"
" nnoremap ee :call SelectBuffer("")<cr>
nnoremap ew :call SelectBuffer("lrc")<cr>
nnoremap ed :call SelectBuffer("delete")<cr>
nnoremap <leader>n :call OpenBufferList()<cr>
" matched lines
let s:category = "mru"
let s:mlinesdict = {}
let s:pwd = getcwd()
let s:bufname = "/tmp/hideseek".tabpagenr().".hideseek"
let s:lrcname = expand("~/.lrc")
augroup bufferSel
  au!
  autocmd VimEnter * OpenBufferList 
  autocmd VimEnter,bufEnter,tabEnter,DirChanged * execute "Hideseek ".s:category
  autocmd DirChanged * call NERDTreeCWD1()
augroup END

function hideseek#addDict(key,value)
  let s:mlinesdict[a:key] = a:value
endfunction
function hideseek#clearDict()
  let s:mlinesdict = {}
endfunction
function hideseek#test()
  echo s:mlinesdict
endfunction

function hideseek#setCategory(category)
  let s:category = a:category
endfunction

function hideseek#getBufnr()
  let tabnr = tabpagenr()
  let s:bufname = "/tmp/hideseek".tabnr.".hideseek"
  let bufnr = bufadd(s:bufname)
  call bufload(bufnr)
  return bufnr
endfunction

function NERDTreeCWD1()
  for i in tabpagebuflist()
    if (bufname(i) =~ "NERD")
      execute "NERDTreeClose"
      execute "NERDTreeCWD"
    endif
  endfor
endfunction

function! OpenBufferList()
  let activebuffers = tabpagebuflist()
  let bufnr = bufadd(s:bufname)
  call bufload(bufnr)
  let filterbuffers = filter(copy(activebuffers),'v:val == bufnr')
  if len(filterbuffers) == 1
    for i in range(winnr('$')+1)
      if winbufnr(i) == bufnr
        try
          execute i."windo buffer NERD"
          execute "NERDTreeCWD"
        catch /^Vim\%((\a\+)\)\=:E/
          execute i."wincmd c"
          execute "NERDTree"
        endtry
        redraw
      endif
    endfor
  else
    try
      execute "NERDTreeClose"
    catch /^Vim\%((\a\+)\)\=:E/
    endtry

    execute "vert topleft sbuffer ".bufnr." \| vert resize 32"
    setlocal nonumber norelativenumber buftype=nofile bufhidden=hide nobuflisted noswapfile wrap
          \ modifiable  nocursorline nofoldenable
    execute "wincmd p"
  endif
endfunction

function hideseek#setHightLight()
  let bufnr = hideseek#getBufnr()
  let currbuf = expand("%:p")
  let matched = 0
  for key in keys(s:mlinesdict)
    if(s:mlinesdict[key]['path'] == currbuf)
      let matched = matched + 1
      call s:setcurrbufhl(bufnr,key)
    endif
  endfor
  if(!matched)
    call setbufvar(bufnr, "&syntax","off")
    call setbufvar(bufnr, "&syntax","on")
  endif
endfunction


function SelectBuffer(type) abort
  let charr = s:inputtarget()
  let head=charr[:-2]
  let tail=charr[-1:-1]
  if (a:type == "lrc")
    try
      let lrcline = s:mlinesdict[''.head]['path']
    catch /^Vim\%((\a\+)\)\=:E/
    endtry
     
    if tail =~ "e"
      silent exe 'e ' ..lrcline 
    else
      silent exe 'vsp ' ..lrcline 
    endif
  elseif (a:type == "delete")
    let head = s:mlinesdict[''.head]['lrc_num']
    let g:test = head
    call system("inoswp -s ".head)
    execute "sleep"
    execute "Hideseek ".s:category
  else
    if tail =~ "e"
      silent exe 'e #' ..head 
    else
      silent exe 'vsp #' ..head 
    endif
  endif
endfunction

function! s:getchar()
  let c = getchar()
  if c =~ '^\d\+$'
    let c = nr2char(c)
  endif
  return c
endfunction
function! s:inputtarget()
  let bufnr = bufnr(s:bufname)
  let c = s:getchar()
  " clear bufferSel augroup
  augroup bufferSel
    au!
  augroup END
  call s:setcurrbufhl(bufnr,c)
  " set buffersel augroup
  augroup bufferSel
    au!
    autocmd VimEnter * OpenBufferList 
    autocmd VimEnter,bufEnter,tabEnter,DirChanged * execute "Hideseek ".s:category
    autocmd DirChanged * call NERDTreeCWD1()
  augroup END
  while c =~ '^\d\+$'
    let c .= s:getchar()
  endwhile
  if c == " "
    let c .= s:getchar()
  endif
  if c =~ "\<Esc>\|\<C-C>\|\0"
    return ""
  else
    return c
  endif
endfunction

function hideseek#clearAllLines(bufnr,linenr)
  let bufnr = a:bufnr
  let linenr = a:linenr
  if (linenr == 0 )
    return 0
  endif
  call deletebufline(bufnr,linenr)
  let linenr = linenr - 1
  return  hideseek#clearAllLines(bufnr,linenr)
endfunction

function hideseek#getbuflinenr(bufnr)
  return len(getbufline(a:bufnr,0,'$')) -1
endfunction

function s:setcurrbufhl(bufnr, line)
  call setbufvar(a:bufnr, "&syntax","off")
  call setbufvar(a:bufnr, "&syntax","on")
  execute 'windo syntax region hideseekSelected start=/\%'.(a:line+1).'l\%5c/ end=/$/'
  redraw
endfunction

function Generatetree(mlines)
  let obj = {}
  let obj.id = 0
  let obj.children = []
  for line in a:mlines
    call Dofunc(obj,line)
  endfor
  return obj
endfunction
" TODO 行号需要节点绑定
function Dofunc(obj,line)
  let obj = a:obj
  let line = a:line
  let line.fullpath = line['path']
  if (obj['id'] == 0)
    let obj.path = s:pwd
    let line.path = substitute(line['path'],s:pwd,"","")
  endif
  if (obj['id'] != 0)
    let newobj ={}
    let newobj.path = line['path']
    let newobj.lrc_num = line['lrc_num']
    let newobj.index = line['index']
    let newobj.fullpath = line['fullpath']
    call add(obj.children,newobj)
    return
  endif 
  let result = FindWays(line['path'])
  if exists('result.line')
    let line.path = result['line']
    let tmp = filter(copy(obj.children),"v:val.path == result.path")
    if(len(tmp) == 1)
      return Dofunc(tmp[0],line)
    else
      let newobj={}
      let newobj.path = result.path
      let newobj.children = []
      let newobj.id = 1
      call insert(obj.children,newobj)
      return Dofunc(newobj,line)
    endif
  else
    let newobj ={}
    let newobj.path = result['path']
    let newobj.lrc_num = line['lrc_num']
    let newobj.index = line['index']
    let newobj.fullpath = line['fullpath']
    call add(obj.children,newobj)
  endif
endfunction

function FindWays(line)
  let line = a:line
  if len(line) > 0
    let slashs = GetSlashs(line)
    let slashcount = len(slashs)
    if(slashcount >= 3)
      if(slashcount % 2 > 0)
        let slashcount = slashcount + 1
      endif
      let whichslash = slashcount/2
      let splitpoint = slashs[whichslash]
      let path = line[:splitpoint-1]
      let line = line[splitpoint:-1]
      return {'path':path,'line':line}
    endif
    return {'path':line}
  endif
endfunction

function GetSlashs(line)
  let num = 0
  let slashs = []
  for index in range(len(a:line))
    let charnr = char2nr(a:line[index])
    if charnr == 47    "char  slash '/' = 47
     call add(slashs,index)
    endif
  endfor
  return slashs
endfunction

command! -bar -nargs=0 OpenBufferList :call OpenBufferList()  

command! -nargs=* -bang -complete=customlist,hideseek#Any#parseArguments Hideseek call hideseek#Any#start(<bang>0, <q-args>)
