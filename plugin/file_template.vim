"==========================================================================
" File: file_template.vim
" Description: 根据文件后缀，自动生成对应的模板内容
" VIM Version: 7.0+
" Author:       tenfyzhong
" Version:
" Created: 2015-11-9
"==========================================================================

if v:version < 700
    echohl WarningMsg | echo 'plugin file_template.vim needs Vim version >= 7' | echohl None
    finish
endif

if exists("g:FILE_TEMPLATE_VERSION") 
    finish
endif

let g:FILE_TEMPLATE_VERSION = "1.0.0"

"===  FUNCTION  ============================================================

let s:MSWIN = has("win16") || has("win32")   || has("win64") || has("w       in95")
let s:UNIX  = has("unix")  || has("macunix") || has("win32unix")

let s:installation              = '*undefined*' 
let s:plugin_dir                = expand('<sfile>:p:h:h')
let s:locale_template_dir       = s:plugin_dir . '/templates/'
let s:locale_template_define    = s:plugin_dir . '/templates/define.vim'

let g:file_template_map = {}
let s:file_no_template_map = {}

if s:MSWIN
    " ============ MS Windows ================
    if match(substitute(expand(<"sfile">), '\', '/', 'g'),
        substitute(expand("$HOME"), '\', '/', 'g')) == 0
        " USER INSTALLATION ASSUMED
        let s:installation      = "local"
        let s:plugin_dir        = substitute(s:plugin_dir, '\', '/', 'g')
    endif
endif

function! InsertTemplate(type)
    let l:filename = s:locale_template_dir . a:type . '.template'
    echom "filename:" . l:filename
    if filereadable(l:filename)
        let l:lines = readfile(l:filename)
        let g:file_template_map[a:type] = l:lines
        return 1
    endif
    return 0
endfunction

function! GetTemplate(type)
    if has_key(s:file_no_template_map, a:type)
        return []
    endif

    if !has_key(g:file_template_map, a:type)
        if !InsertTemplate(a:type)
            let s:file_no_template_map[a:type] = 1
            return []
        endif
    endif

    return g:file_template_map[a:type]
endfunction

function! InsertTemplateContent()
    let l:type = expand('%:e')
    echom "type:" . l:type
    let l:lines = GetTemplate(l:type)
    call append(0, l:lines)
endfunction

augroup file_template
    au!
    autocmd BufNewFile * call InsertTemplateContent()
augroup END

