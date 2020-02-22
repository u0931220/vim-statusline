if exists('g:loaded_statusline')
    finish
endif

let g:loaded_statusline = 1

" Dictionary mapping of all different modes to the text that should be displayed.
let s:sl_current_mode={
                      \'n' : 'Normal',
                      \'no' : 'Normal·Operator Pending',
                      \'v' : 'Visual',
                      \'V' : 'V·Line',
                      \"\<C-v>" : 'V·Block',
                      \'s' : 'Select',
                      \'S' : 'S·Line',
                      \"\<C-s>" : 'S·Block',
                      \'i' : 'Insert',
                      \'R' : 'Replace',
                      \'Rv' : 'V·Replace',
                      \'c' : 'Command',
                      \'cv' : 'Vim Ex',
                      \'ce' : 'Ex',
                      \'r' : 'Prompt',
                      \'rm' : 'More',
                      \'r?' : 'Confirm',
                      \'!' : 'Shell',
                      \'t' : 'Terminal'
                      \}

" Set statusline based on window focus
function! statusline#status()
    " Determine which window is focused
    let l:focused = s:statusline_winid == win_getid(winnr())

    " Setup the statusline formatting
    let l:statusline=""
    let l:statusline=focused ? "%#Status1#" : "%#StatusLineNC#"       " First color block, see dim.vim
    let l:statusline.="\ %{toupper(s:sl_current_mode[mode()])}\ "     " The current mode
    let l:statusline.=focused ? "%#Status2#" : "%#StatusLineNC#"      " Second color block
    let l:statusline.="\ %<%F%m%r%h%w\ "                              " File path, modified, readonly, helpfile, preview
    let l:statusline.=focused ? "%#Status3#" : "%#StatusLineNC#"      " Third color block
    let l:statusline.="\ %Y"                                          " Filetype
    let l:statusline.="\ %{''.(&fenc!=''?&fenc:&enc).''}"             " Encoding
    let l:statusline.="\ %{&ff}\ "                                    " FileFormat (dos/unix..)
    let l:statusline.=focused ? "%#Status4#" : "%#StatusLineNC#"      " Second color block
    let l:statusline.="%{s_git_branch_name()}"                        " Git info
    let l:statusline.=focused ? "%#Status5#" : "%#StatusNone#"        " No color
    let l:statusline.="%="                                            " Right Side
    let l:statusline.=focused ? "%#Status4#" : "%#StatusLineNC#"      " Third color block
    let l:statusline.="\ col:\ %02v"                                  " Colomn number
    let l:statusline.="\ ln:\ %02l/%L\ (%3p%%)\ "                     " Line number / total lines, percentage of document
    let l:statusline.=focused ? "%#Status1#" : "%#StatusLineNC#"      " First color block, see dim
    let l:statusline.="\ %n\ "                                        " Buffer number

    return l:statusline
endfunction

" Get the name of the current git branch if it exists
function! s:git_branch_name() abort
    if get(b:, "gitbranch_pwd", "") !=# expand("%:p:h") || !has_key(b:, "gitbranch_path")
        call s:git_detect(expand("%:p:h"))
    endif

    if has_key(b:, "gitbranch_path") && filereadable(b:gitbranch_path)
        let branch = get(readfile(b:gitbranch_path), 0, "")

        if branch =~# "^ref: "
            return " " . substitute(branch, '^ref: \%(refs/\%(heads/\|remotes/\|tags/\)\=\)\=', "", "") . " "
        elseif branch =~# '^\x\{20\}'
            return " " . branch[:6] . " "
        endif

    endif

    return ""
endfunction

" Find git information based on the location of a buffer
function! s:git_branch_dir(path) abort
    let l:path = a:path
    let l:prev = ""

    while l:path !=# prev
        let l:dir = l:path . "/.git"
        let l:type = getftype(dir)

        if l:type ==# "dir" && isdirectory(l:dir . "/objects")
                            \ && isdirectory(l:dir . "/refs")
                            \ && getfsize(l:dir . "/HEAD") > 10
            return l:dir
        elseif l:type ==# "file"
            let l:reldir = get(readfile(l:dir), 0, "")

            if l:reldir =~# "^gitdir: "
                return simplify(l:path . "/" . l:reldir[8:])
            endif
        endif

        let l:prev = l:path
        let l:path = fnamemodify(l:path, ":h")

    endwhile

    return ""
endfunction

" Detect if a directory is part of a git directory.
function! s:git_detect(path) abort
    unlet! b:gitbranch_path
    let b:gitbranch_pwd = expand("%:p:h")
    let l:dir = s:git_branch_dir(a:path)

    if l:dir !=# ""
        let l:path = dir . "/HEAD"

        if filereadable(l:path)
            let b:gitbranch_path = l:path
        endif
    endif
endfunction

augroup statusline
    au!

    " Ensure the statusline gets drawn if 'lazyredraw' is enabled.
    au VimEnter * redraw

    " Update Git branch information based on certain events.
    au BufNewFile,BufReadPost * call GitDetect(expand("<amatch>:p:h"))
    au BufEnter * call GitDetect(expand("%:p:h"))
augroup END
