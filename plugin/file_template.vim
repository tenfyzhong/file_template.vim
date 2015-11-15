"==============================================================
" File: file_template.vim
" Brief: 根据文件后缀，自动生成对应的模板内容
" VIM Version: 7.0+
" Author:       tenfyzhong
" Version:
" Date: 2015-11-9
"==============================================================

if v:version < 700
    echohl WarningMsg | echo 'plugin file_template.vim needs Vim version >= 7' | echohl None
    finish
endif

if exists("g:FILE_TEMPLATE_VERSION") 
    finish
endif

let g:FILE_TEMPLATE_VERSION = "1.0.0"

"===  FUNCTION  ===============================================

let s:MSWIN = has("win16") || has("win32")   || has("win64") || has("w       in95")
let s:UNIX  = has("unix")  || has("macunix") || has("win32unix")

let s:installation              = '*undefined*' 
let s:plugin_dir                = expand('<sfile>:p:h:h')
let s:locale_template_dir       = s:plugin_dir . '/templates/'
let s:locale_template_define    = s:plugin_dir . '/templates/macro'

let g:file_template_map     = {}
let s:file_no_template_map  = {}
let s:macro_value_map       = {}
let s:has_init_macro        = 0

if s:MSWIN
    " ============ MS Windows ================
    if match(substitute(expand(<"sfile">), '\', '/', 'g'),
        substitute(expand("$HOME"), '\', '/', 'g')) == 0
        " USER INSTALLATION ASSUMED
        let s:installation      = "local"
        let s:plugin_dir        = substitute(s:plugin_dir, '\', '/', 'g')
    endif
endif

function! InitStaticMacro(macro_file)
    if s:has_init_macro == 1
        return
    endif

    if filereadable(a:macro_file)
        let s:has_init_macro = 1
        let l:lines = readfile(a:macro_file)
        for l in l:lines
            let l:items = matchlist(l, '^\s\(|\w*|\)\s*=\s*\(.*\)\s*$')
            if len(l:items) < 2
                continue
            endif
            let l:macro = get(l:items, 1, '')
            let l:value = get(l:items, 2, '')
            let l:value = substitute(l:value, '|', '_', 'g')
            let s:macro_value_map[l:macro] = l:value
        endfor
    endif
endfunction

function! InitDynamicMacro()
    " init time use function strftime
    let l:datetime      = strftime("%Y %m %d %T")
    let l:time_itmes    = split(l:datetime)
    if len(l:time_itmes) >= 4
        let s:macro_value_map['|YEAR|']   = l:time_itmes[0]
        let s:macro_value_map['|MONTH|']  = l:time_itmes[1]
        let s:macro_value_map['|DAY|']    = l:time_itmes[2]
        let s:macro_value_map['|TIME|']   = l:time_itmes[3]
    endif
    let s:macro_value_map['|FILE|'] = expand('%:t')
endfunction

function! InsertTemplate(type)
    let l:filename = s:locale_template_dir . a:type . '.ftemplate'
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
    if l:type == ""
        return
    endif

    call InitStaticMacro(s:locale_template_define)
    call InitDynamicMacro()

    let l:lines = GetTemplate(l:type)
    let l:sub_macro_lines = []
    for l in l:lines
        let l:after_macro = l
        let l:keys = keys(s:macro_value_map)
        for k in l:keys
            let l:value = get(s:macro_value_map, k, '')
            let l:after_macro = substitute(l:after_macro, k, l:value, 'g')
        endfor
        call add(l:sub_macro_lines, l:after_macro)
    endfor
    call append(0, l:sub_macro_lines)
endfunction

augroup file_template
    au!
    autocmd BufNewFile * call InsertTemplateContent()
augroup END

