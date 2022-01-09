" Copyright (c) 2022 zhongzhong

let s:cpo_save = &cpo
set cpo&vim

" Default options
let s:default_delay = 0
let s:default_once_window = 'bel 15new'
let s:default_keep_window = 'vert lefta 30new'
let s:default_compact = 0

let s:PWD = getcwd()
let g:pwd = s:PWD
  let s:buffers = {}

let s:buf_hideseek = 0

" Returns true if timed out
function! s:wait_with_timeout(timeout)
  let timeout = a:timeout
  while timeout >= 0
    if getchar(1)
      return 0
    endif
    if timeout > 0
      sleep 20m
    endif
    let timeout -= 20
  endwhile
  return 1
endfunction

" Checks if Peekaboo buffer is open
function! s:is_open()
  return s:buf_hideseek
endfunction

" Closes hideseek buffer
function! s:close()
  silent! execute 'bd' s:buf_hideseek
  let s:buf_hideseek = 0
  execute s:winrestcmd
endfunction

" Appends macro list for the specified group to Peekaboo window
function! s:append_group(title, buffers)
  let compact = get(g:, 'hideseek_compact', s:default_compact)
  if !compact | call append(line('$'), a:title.':') | endif
  if !compact | call append(line('$'), s:PWD) | endif
  for b in a:buffers 
    try
      let b = substitute(b,'[\x7E]',$HOME,"")
      let b = substitute(b,s:PWD,".",'')
      call append(line('$'), printf('%s',b))
      let parts = split(b," ") 
      let s:buffers[parts[0]] = line('$') 
    catch
    endtry
  endfor
  if !compact | call append(line('$'), '') | endif
endfunction

" Opens hideseek window
function! s:open(mode)
  let [s:buf_current, s:buf_alternate, s:winrestcmd] = [@%, @#, winrestcmd()]
  if a:mode == "once"
    execute get(g:, 'hideseek_window', s:default_once_window)
  else
    execute get(g:, 'hideseek_window', s:default_keep_window)
  endif
  let s:buf_hideseek = bufnr('')
  setlocal nonumber buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap
  \ modifiable statusline=>\ Buffers nocursorline nofoldenable
  if exists('&relativenumber')
    setlocal norelativenumber
  endif

  setfiletype hideseek
  augroup hideseek
    autocmd!
    autocmd CursorMoved <buffer> bd
  augroup END

  call <SID>append_group('buffer', split(execute('ls'),'\n'))
  " normal! "_dd
endfunction

" Checks if the buffer for the position is visible on screen
function! s:is_visible(pos)
  return a:pos.tab == tabpagenr() && bufwinnr(a:pos.buf) != -1
endfunction

" Triggers gv to keep visual highlight on
function! s:gv(visualmode, visible)
  if a:visualmode && a:visible
    noautocmd wincmd p
    normal! gv
    redraw
    noautocmd wincmd p
  else
    redraw
  endif
endfunction


let s:scroll = {
\ "\<up>":     "\<c-y>", "\<down>":     "\<c-e>",
\ "\<c-y>":    "\<c-y>", "\<c-e>":      "\<c-e>",
\ "\<c-u>":    "\<c-u>", "\<c-d>":      "\<c-d>",
\ "\<c-b>":    "\<c-b>", "\<c-f>":      "\<c-f>",
\ "\<pageup>": "\<c-b>", "\<pagedown>": "\<c-f>"
\ }

" Returns the position of the current buffer as a dictionary
function! s:getpos()
  return {'tab': tabpagenr(), 'buf': bufnr(''), 'win': winnr(), 'cnt': winnr('$')}
endfunction

function! hideseek#hide(count, mode, visualmode)
  " First check if we should start hideseek, if not just return the mode key
  let timeout = get(g:, 'hideseek_delay', s:default_delay)
  if !s:wait_with_timeout(timeout)
    return a:mode
  endif

  let s:args = [a:count, a:mode, a:visualmode]
  return "\<Plug>(hideseek)"
endfunction

function! hideseek#seek()
  let [cnt, mode, visualmode] = s:args

  if s:is_open()
    call s:close()
  endif

  let positions = { 'current': s:getpos() }
  call s:open(mode)
  if mode == "keep"
    return 0
  endif
  let positions.hideseek = s:getpos()

  let inplace = positions.current.tab == positions.hideseek.tab &&
        \ positions.current.win == positions.hideseek.win &&
        \ positions.current.cnt == positions.hideseek.cnt
  let visible = !inplace && s:is_visible(positions.current)

  call s:gv(visualmode, visible)

  let [stl, lst] = [&showtabline, &laststatus]
  let zoom = 0
  try
    while 1
      let ch  = getchar()
      let bufnum = nr2char(ch)
      let key = get(s:scroll, ch, get(s:scroll, bufnum, ''))
      if !empty(key)
        execute 'normal!' key
        call s:gv(visualmode, visible)
        continue
      endif

      if zoom
        tab close
        let [&showtabline, &laststatus] = [stl, lst]
        call s:gv(visualmode, visible)
      endif
      if bufnum != ' '
        break
      endif
      if !zoom
        tab split
        set showtabline=0 laststatus=0
      endif
      let zoom = !zoom
      redraw
    endwhile

    let rest = ''
    while 1
      let g:buffers = s:buffers
      if has_key(s:buffers, tolower(bufnum))
        let line = s:buffers[tolower(bufnum)]
        let g:line = line
        setlocal syntax=off
        setlocal syntax=on
        execute line
        execute 'syntax region hideseekSelected start=/\%'.line.'l\%5c/ end=/$/'
        setlocal cursorline
        call s:gv(visualmode, visible)
        if bufnum =~ '^\d\+$'
          echom ""
        else
          return
        endif
        let rest = nr2char(getchar())
          if rest =~ '^\d\+$'
            let bufnum .= rest
            let rest = ''
          else
            break
          endif
        else
          echom("buffer not exists")
          return
      endif
    endwhile

    " - Make sure that we're back to the original tab/window/buffer
    "   - e.g. g:hideseek_window = 'tabnew' / 'enew'
    if inplace
      noautocmd execute positions.current.win.'wincmd w'
      noautocmd execute 'buf' positions.current.buf
    else
      noautocmd execute 'tabnext' positions.current.tab
      call s:close()
      noautocmd execute positions.current.win.'wincmd w'
    endif
    if visualmode
      normal! gv
    endif
    if rest == 'q'
      execute "vert sb".bufnum
    else
      execute "buffer ".bufnum
    endif
  catch /^Vim:Interrupt$/
    return
  finally
    let [&showtabline, &laststatus] = [stl, lst]
    " call s:close()
    redraw
  endtry
endfunction

" bufferSel
nnoremap <expr> e SelectBuffer("") ..'_'
" xnoremap <expr> <F4> SelectBuffer()
" doubling <F4> works on a line
" nnoremap <expr> <F4><F4> CountSpaces() .. '_'
nnoremap  <leader>bb :execute 'Bss'<CR>
" nnoremap <leader>SetTcd :execute 'SetTcd'<CR>
augroup bufferSel
    au!
     autocmd bufEnter * call LRCread()
     autocmd bufEnter,tabEnter * call BufferRead()
augroup END

function! LRCread()
    let $pwd= getcwd()
    let $lrcfilename = g:LRCfileName
    let currbufnr = bufnr("%")
    let currbufname = expand('#'.currbufnr.':p') 
    if (currbufname == "")
        execute "" 
    elseif (match(currbufname,"/tmp")> -1)
        execute "" 
    elseif (match(currbufname,"/.git")> -1)
        execute "" 
    else
          execute "silent ! echo ".currbufname." >> " . $lrcfilename
    endif
    let l:command = "sh ". expand("~/dotfile/vim/script/LRC.sh") ." ". $lrcfilename ." " . $pwd
    if has("nvim")
        let job = jobstart(l:command, {"in_io": "null", "out_io": "null", "err_io": "null"})
    else
        let job = job_start(l:command, {"in_io": "null", "out_io": "null", "err_io": "null"})
    end
endfunction

function! BufferRead()
    let pwd= getcwd()
    let $bufferListFileName = g:bufferListFileName
    let g:test1 = $bufferListFileName
    execute "silent !echo ".pwd." >" . $bufferListFileName
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
            execute "silent ! echo ".bufname." >> " . $bufferListFileName
          endif
        endif
        let currbufnr = currbufnr + 1
    endwhile
endfunction
function! s:bufSelPwd()
    let pwd=getcwd()
    call s:bufSel(pwd)
endfunction

function! s:bufSel(pattern)
  let bufcount = bufnr("$")
  let currbufnr = 1
  let nummatches = 0
  let firstmatchingbufnr = 0
  while currbufnr <= bufcount
    if(bufexists(currbufnr))
      let currbufname = expand('#'.currbufnr.':p') 
      if(match(currbufname, a:pattern) > -1)
        echo currbufnr . ": ".expand('#'.currbufnr.':p:.')
        let nummatches += 1
        let firstmatchingbufnr = currbufnr
      endif
    endif
    let currbufnr = currbufnr + 1
  endwhile
  if(nummatches == 1)
    execute ":buffer ". firstmatchingbufnr
  elseif(nummatches > 1)
    let desiredbufnr = input("Enter buffer number: ")
    if(strlen(desiredbufnr) != 0)
      execute ":buffer ". desiredbufnr
    endif
  else
    echo "No matching buffers"
  endif
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
  let g:aaa=reg_save
  let cb_save = &clipboard
  let visual_marks_save = [getpos("'<"), getpos("'>")]

  try
    set clipboard= selection=inclusive
  finally
  let charr = s:inputtarget()
  let head=charr[:-2]
  let tail=charr[-1:-1]
  let g:aa=head
  let g:bb=tail
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

"Bind the s:bufSel() function to a user-command
command! -nargs=1 Bs :call s:bufSel("<args>")
command! -nargs=0 Bss :call s:bufSelPwd()
" command! -nargs=0 SetTcd :call s:setTcd()

let &cpo = s:cpo_save
unlet s:cpo_save
