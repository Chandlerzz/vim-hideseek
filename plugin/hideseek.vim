" The MIT License (MIT)
"
" Copyright (c) 2017 Junegunn Choi
"
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to deal
" in the Software without restriction, including without limitation the rights
" to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
" copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:
"
" The above copyright notice and this permission notice shall be included in
" all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
" OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
" THE SOFTWARE.

nnoremap <silent> <Plug>(hideseek) :<c-u>call hideseek#aboo()<cr>
" xnoremap <silent> <Plug>(hideseek) :<c-u>call hideseek#aboo()<cr>
" inoremap <silent> <Plug>(hideseek) <c-\><c-o>:<c-u>call hideseek#aboo()<cr>

function! hideseek#on()
  if get(b:, 'hideseek_on', 0)
    return
  endif

  let prefix = get(g:, 'hideseek_prefix', '')
  let ins_prefix = get(g:, 'hideseek_ins_prefix', '')
  execute 'nmap <buffer> <expr> '.prefix.    '<leader>e     hideseek#peek(v:count1, ''"'',  0)'
  let b:hideseek_on = 1
  return ''
endfunction

function! hideseek#off()
  if !get(b:, 'hideseek_on', 0)
    return
  endif

  let prefix = get(g:, 'hideseek_prefix', '')
  let ins_prefix = get(g:, 'hideseek_ins_prefix', '')
  execute 'nunmap <buffer> '.prefix.'"'
  let b:hideseek_on = 0
endfunction

augroup hideseek_init
  autocmd!
  autocmd BufEnter * if !exists('*getcmdwintype') || empty(getcmdwintype()) | call hideseek#on() | endif
augroup END

