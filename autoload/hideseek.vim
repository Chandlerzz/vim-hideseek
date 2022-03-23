" Copyright (c) 2022 zhongzhong

if !exists("g:Hs_PythonVersion")
    if has("python3")
        let g:Hs_PythonVersion = 3
        let g:Hs_py = "py3 "
    elseif has("python")
        let g:Hs_PythonVersion = 2
        let g:Hs_py = "py "
    else
        echoe "Error: HideSeek requires vim compiled with +python or +python3"
        finish
    endif
else
    if g:Hs_PythonVersion == 2
        if has("python")
            let g:Hs_py = "py "
        else
            echoe 'HideSeek Error: has("python") == 0'
            finish
        endif
    else
        if has("python3")
            let g:Hs_py = "py3 "
        else
            echoe 'HideSeek Error: has("python3") == 0'
            finish
        endif
    endif
endif

function! hideseek#versionCheck()
    if g:Lf_PythonVersion == 2 && pyeval("sys.version_info < (2, 7)")
        echohl Error
        echo "Error: LeaderF requires python2.7+, your current version is " . pyeval("sys.version")
        echohl None
        return 0
    elseif g:Lf_PythonVersion == 3 && py3eval("sys.version_info < (3, 1)")
        echohl Error
        echo "Error: LeaderF requires python3.1+, your current version is " . py3eval("sys.version")
        echohl None
        return 0
    elseif g:Lf_PythonVersion != 2 && g:Lf_PythonVersion != 3
        echohl Error
        echo "Error: Invalid value of `g:Lf_PythonVersion`, value must be 2 or 3."
        echohl None
        return 0
    endif
    return 1
endfunction

if exists('g:f#loaded')
    finish
else
    let g:hideseek#loaded = 1
endif


function! s:InitVar(var, value)
    if !exists(a:var)
        exec 'let '.a:var.'='.string(a:value)
    endif
endfunction

function! s:InitDict(var, dict)
    if !exists(a:var)
        exec 'let '.a:var.'='.string(a:dict)
    else
        let tmp = a:dict
        for [key, value] in items(eval(a:var))
            let tmp[key] = value
        endfor
        exec 'let '.a:var.'='.string(tmp)
    endif
endfunction

function! hideseek#HsPy(cmd)
  g:Hs_py a:cmd
endfunction


