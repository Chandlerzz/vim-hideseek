
if hideseek#versionCheck() == 0  " this check is necessary
    finish
endif

exec g:Hs_py "from hideseek.anyExpl import *"


let g:Rs_Helps = {
            \ }

let g:Rs_Arguments = {
            \}

let g:Rs_CommonArguments = [
            \]

function! s:Hs_Refine(arguments) abort
    let result = []
    for arg in a:arguments
        if type(arg) == type([])
            let sublist = []
            for i in arg
                let sublist += i["name"]
            endfor
            call add(result, sublist)
        else
            call extend(result, arg["name"])
        endif
    endfor
    return result
endfunction


function! hideseek#Any#parseArguments(argLead, cmdline, cursorPos) abort
endfunction

" this function is main function. here is the start
function! hideseek#Any#start(bang, args) abort
    if a:args == ""

    else
        call hideseek#LfPy("anyHub.start(r''' ".a:args." ''', bang=".a:bang.")")
    endif
endfunction


" command! -nargs=* -bang -complete=customlist,hideseek#Any#parseArguments Leaderf call hideseek#Any#start(<bang>0, <q-args>)
