" bufferSel
nnoremap <expr> e SelectBuffer("") ..'_'
nnoremap <leader>e :call OpenBufferList()<cr>
if has('nvim')
  let s:bufname = "/tmp/bufferList/".luaeval('math.random(1000000,1000000000)').".hideseek"
else 
  let s:bufname = "/tmp/bufferList/".rand().".hideseek"
endif
let s:lrcname = expand("~/.lrc")
augroup bufferSel
    au!
     " autocmd bufEnter * call LRCread()
     autocmd bufEnter,tabEnter * call BufferRead()
augroup END

function! OpenBufferList()
  let activebuffers = tabpagebuflist()
  let bufnr = bufadd(s:bufname)
  call bufload(bufnr)
  let filterbuffers = filter(copy(activebuffers),'v:val == bufnr')
  if len(filterbuffers) == 1
    for i in range(winnr('$')+1)
      if winbufnr(i) == bufnr
        execute i."wincmd c"
        redraw
      endif
    endfor
  else
    execute "vert topleft sbuffer ".bufnr." \| vert resize 40"
    setlocal nonumber norelativenumber  nobuflisted noswapfile nowrap
    \ modifiable statusline=>\ Buffers nocursorline nofoldenable
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
    let firstmatchingbufnr = 0
    while currbufnr <= bufcount
        if(bufexists(currbufnr))
          let currbufname = expand('#'.currbufnr.':p') 
          if(match(currbufname, pwd) > -1)
            let bufname = currbufnr . ": ".expand('#'.currbufnr.':p:.')
            let nummatches += 1
            call setbufline(bufnr,nummatches,bufname)
          endif
        endif
        let currbufnr = currbufnr + 1
    endwhile
    let lrclines = system("cat ".s:lrcname)
    let lrclines = split(lrclines,"\n")
    for lrcline in lrclines 
      if(match(lrcline, pwd) > -1)
        let lrcline = split(lrcline,"%")[0]
        let lrcline = substitute(lrcline,pwd,"","")
        let nummatches += 1
        call setbufline(bufnr,nummatches,lrcline)
      endif
    endfor
endfunction


function SelectBuffer(type) abort
  if a:type == ''
    set opfunc=SelectBuffer
    return 'g@'
  endif

  let sel_save = &selection
  if has("nvim")
      let reg_save = @@
  else
      let reg_save = getreginfo('"')
  end
  let cb_save = &clipboard
  let visual_marks_save = [getpos("'<"), getpos("'>")]

  try
    set clipboard= selection=inclusive
  finally
  let charr = s:inputtarget()
  let head=charr[:-2]
  let tail=charr[-1:-1]
  if tail =~ "e"
      silent exe 'e #' ..head 
  else
      silent exe 'vsp #' ..head 
  endif
    call setreg('"', reg_save)
    call setpos("'<", visual_marks_save[0])
    call setpos("'>", visual_marks_save[1])
    let &clipboard = cb_save
    let &selection = sel_save
endtry
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


