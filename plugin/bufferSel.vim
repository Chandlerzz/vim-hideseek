" bufferSel
nnoremap ee :call SelectBuffer("")<cr>
nnoremap ew :call SelectBuffer("lrc")<cr>
nnoremap ed :call SelectBuffer("delete")<cr>
nnoremap <leader>n :call OpenBufferList()<cr>
if has('nvim')
  let s:bufname = "/tmp/bufferList/".luaeval('math.random(1000000,1000000000)').".hideseek"
else 
  let s:bufname = "/tmp/bufferList/".rand().".hideseek"
endif
let s:lrcname = expand("~/.lrc")
augroup bufferSel
    au!
     autocmd VimEnter,bufEnter,tabEnter,DirChanged * call BufferRead()
     autocmd DirChanged * call NERDTreeCWD1()
     autocmd VimEnter * OpenBufferList 
augroup END

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
    \ modifiable statusline=>\ Buffers nocursorline nofoldenable
    setlocal filetype=hideseek
    execute "wincmd p"
  endif
endfunction

function! LRCread()
    let pwd= getcwd()
endfunction

function! BufferRead()
    let pwd= getcwd()
    let bufnr = bufadd(s:bufname)
    call bufload(bufnr)
    let linenr = len(getbufline(bufnr,1,'$'))
    call s:clearAllLines(bufnr,linenr)
    let bufcount = bufnr("$")
    let currbufnr = 1
    let nummatches = 1
    " set header buffers 
    " call setbufline(bufnr, nummatches, "BUFFERS")
    " let nummatches = nummatches + 1
    " while currbufnr <= bufcount
    "     if(bufexists(currbufnr))
    "       let currbufname = expand('#'.currbufnr.':p') 
    "       if(match(currbufname, pwd) > -1)
    "         let bufname = currbufnr . ": ".expand('#'.currbufnr.':p:.')
    "         call setbufline(bufnr,nummatches,bufname)
    "         let nummatches += 1
    "       endif
    "     endif
    "     let currbufnr = currbufnr + 1
    " endwhile
    " set header lrc
    call setbufline(bufnr, nummatches, "LRC")
    let nummatches += 1
    let lrclines = system("cat ".s:lrcname)
    let lrclines = split(lrclines,"\n")
    for index in range(len(lrclines)) 
      let lrcline = lrclines[index]
      if(match(lrcline, pwd) > -1)
        let lrcline = split(lrcline,"%")[0]
        let lrcline = substitute(lrcline,pwd,"","")
        let lrcline = (index+1).": ".lrcline
        call setbufline(bufnr,nummatches,lrcline)
        let nummatches += 1
      endif
    endfor
endfunction


function SelectBuffer(type) abort
  let charr = s:inputtarget()
  let head=charr[:-2]
  let tail=charr[-1:-1]
  if (a:type == "lrc")
    let lrclines = system("cat ".s:lrcname)
    let lrclines = split(lrclines,"\n")
    let lrcline = lrclines[head-1]
    let lrcline = split(lrcline,"%")[0]
    let g:lrcline = lrcline
    if tail =~ "e"
        silent exe 'e ' ..lrcline 
    else
        silent exe 'vsp ' ..lrcline 
    endif
  elseif (a:type == "delete")
    call system("inoswp -s ".head)
    call BufferRead()
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
  let c = s:getchar()
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

function s:clearAllLines(bufnr,linenr)
  let bufnr = a:bufnr
  let linenr = a:linenr
  if (linenr == 0 )
    return 0
  endif
  call setbufline(bufnr,linenr,"")
  let linenr = linenr - 1
  return  s:clearAllLines(bufnr,linenr)
endfunction


command! -bar -nargs=0 OpenBufferList :call OpenBufferList()  
