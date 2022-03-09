" bufferSel
nnoremap ee :call SelectBuffer("")<cr>
nnoremap ew :call SelectBuffer("lrc")<cr>
nnoremap ed :call SelectBuffer("delete")<cr>
nnoremap <leader>n :call OpenBufferList()<cr>
" matched lines
let s:mlines = []
let s:pwd = getcwd()
let s:bufname = "/tmp/hideseek.hideseek"
let s:lrcname = expand("~/.lrc")
augroup bufferSel
  au!
  autocmd VimEnter * OpenBufferList 
  autocmd VimEnter,bufEnter,tabEnter,DirChanged * call BufferRead()
  autocmd DirChanged * call NERDTreeCWD1()
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
          \ modifiable  nocursorline nofoldenable
    setlocal filetype=hideseek
    execute "wincmd p"
  endif
endfunction

function! BufferRead()
  let oldlines = copy(s:mlines)
  let s:mlines = []
  let s:pwd= getcwd()
  let bufnr = bufadd(s:bufname)
  call bufload(bufnr)
  call setbufvar(bufnr,"&statusline",s:pwd)
  let linenr = len(getbufline(bufnr,0,'$'))
  call s:clearAllLines(bufnr,linenr)
  let linenr = s:getbufnr(bufnr)
  call appendbufline(bufnr, linenr, "MRU:")
  let lrclines = systemlist("cat ".s:lrcname)
  for index in range(len(lrclines)) 
    let lrcline = lrclines[index]
    if(match(lrcline, s:pwd) > -1)
      let linenr = s:getbufnr(bufnr)
      let lrcline = split(lrcline,"%")[0]
      call add(s:mlines, {'num':index+1,'path':lrcline})
      let lrcline = substitute(lrcline,s:pwd,"","")
      let lrcline = len(s:mlines).": ".lrcline
      call appendbufline(bufnr,linenr,lrcline)
      if(len(s:mlines) == 9)
       break 
      endif
    endif
  endfor
  if (len(oldlines) > 0)
    if(len(s:mlines) > 0)
      if(oldlines[0]['path'] != s:mlines[0]['path'])
        if(expand("%:p") == s:mlines[0]['path'])
          call s:setcurrbufhl(bufnr,1)
        else
          call setbufvar(bufnr, "&syntax","off")
          call setbufvar(bufnr, "&syntax","on")
        endif
      endif
    endif
  endif
endfunction


function SelectBuffer(type) abort
  let charr = s:inputtarget()
  let head=charr[:-2]
  let tail=charr[-1:-1]
  if (a:type == "lrc")
    let lrcline = s:mlines[head-1]['path']
    if tail =~ "e"
      silent exe 'e ' ..lrcline 
    else
      silent exe 'vsp ' ..lrcline 
    endif
  elseif (a:type == "delete")
    let head = s:mlines[head-1]['num']
    let g:test = head
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
  let bufnr = bufnr(s:bufname)
  let c = s:getchar()
  while c =~ '^\d\+$'
    let c .= s:getchar()
    call s:setcurrbufhl(bufnr,c)
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
  call deletebufline(bufnr,linenr)
  let linenr = linenr - 1
  return  s:clearAllLines(bufnr,linenr)
endfunction

function s:getbufnr(bufnr)
  return len(getbufline(a:bufnr,0,'$')) -1
endfunction

function s:setcurrbufhl(bufnr, line)
  call setbufvar(a:bufnr, "&syntax","off")
  call setbufvar(a:bufnr, "&syntax","on")
  execute 'windo syntax region hideseekSelected start=/\%'.(a:line+1).'l\%5c/ end=/$/'
  redraw
endfunction


command! -bar -nargs=0 OpenBufferList :call OpenBufferList()  
