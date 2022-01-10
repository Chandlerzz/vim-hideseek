" Copyright (c) 2022 zhongzhong

nnoremap <silent> <Plug>(hideseek) :<c-u>call hideseek#seek()<cr>

function! hideseek#on()
  if get(b:, 'hideseek_on', 0)
    return
  endif

  let prefix = get(g:, 'hideseek_prefix', '')
  let ins_prefix = get(g:, 'hideseek_ins_prefix', '')
  execute 'nmap <buffer> <expr> '.prefix.    '<leader>e     hideseek#hide(v:count1, "keep",  0)'
  execute 'nmap <buffer> <expr> '.prefix.    '<leader>ee     hideseek#hide(v:count1, "once",  0)'
  execute 'badd /tmp/bufferList.hideseek'
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
evert lefta 30new
endfunction

augroup hideseek_init
  autocmd!
  " autocmd BufEnter * if !exists('*getcmdwintype') || empty(getcmdwintype()) | call hideseek#on() | endif
augroup END

