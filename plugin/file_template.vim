"==============================================================
" File: file_template.vim
" Brief: 根据文件后缀，自动生成对应的模板内容
" VIM Version: 7.0+
" Author:       tenfyzhong
" Version:
" Date: 2015-11-9
"==============================================================

" optional {{{
if v:version < 700
    echohl WarningMsg | echo 'plugin file_template.vim needs Vim version >= 7' | echohl None
    finish
endif

if exists("g:FILE_TEMPLATE_VERSION") 
    finish
endif
" }}}

" variable {{{
let g:FILE_TEMPLATE_VERSION = "1.0.0"

let s:MSWIN = has("win16") || has("win32")   || has("win64") || has("win95")
let s:UNIX  = has("unix")  || has("macunix") || has("win32unix")

let s:installation              = '*undefined*' 
let s:plugin_dir                = expand('<sfile>:p:h:h')
let s:template_dir       = s:plugin_dir . '/templates/'
let s:macro_file_name   = "macro"
let s:template_macro    = s:template_dir . s:macro_file_name
let s:local_template_dir = ""
let s:has_local_setting = 0

let s:file_template_map     = {}
let s:filetype_no_template_map  = {}
let s:macro_value_map       = {}
let s:has_init_macro        = 0
let s:has_init_ignore_filetype = 0
" }}}

" substitute '/' to '\' in windows {{{
if s:MSWIN
    " ============ MS Windows ================
    if match(substitute(expand(<"sfile">), '\', '/', 'g'),
        substitute(expand("$HOME"), '\', '/', 'g')) == 0
        " USER INSTALLATION ASSUMED
        let s:installation      = "local"
        let s:plugin_dir        = substitute(s:plugin_dir, '\', '/', 'g')
    endif
endif
" }}}

" s:InitStaticMacro {{{
function! s:InitStaticMacro(macro_file)
    if s:has_init_macro == 1
        return
    endif

    if filereadable(a:macro_file)
        let s:has_init_macro = 1
        let l:lines = readfile(a:macro_file)
        for l in l:lines
            let l:items = matchlist(l, '^\s*\(|\w*|\)\s*=\s*\(.*\)\s*$')
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
" }}}

" s:InitDynamicMacros {{{
function! s:InitDynamicMacro()
    " init time use function strftime
    let l:datetime      = strftime("%Y %m %d %T")
    let l:time_itmes    = split(l:datetime)
    if len(l:time_itmes) >= 4
        let s:macro_value_map['|YEAR|']   = l:time_itmes[0]
        let s:macro_value_map['|MONTH|']  = l:time_itmes[1]
        let s:macro_value_map['|DAY|']    = l:time_itmes[2]
        let s:macro_value_map['|TIME|']   = l:time_itmes[3]
        let s:macro_value_map['|DATETIME|'] = l:time_itmes[0] . '-' . l:time_itmes[1] . '-' . l:time_itmes[2] . ' ' . l:time_itmes[3]
    endif
    let s:macro_value_map['|FILE|'] = expand('%:t')
endfunction
" }}}

" s:InsrtTemplate {{{
function! s:InsertTemplate(type, template_dir)
    let l:filename = a:template_dir . a:type . '.ftemplate'
    if filereadable(l:filename)
        let l:lines = readfile(l:filename)
        let s:file_template_map[a:type] = l:lines
        return 1
    endif
    return 0
endfunction
" }}}

" s:GetTemplate {{{
function! s:GetTemplate(type)
    if has_key(s:filetype_no_template_map, a:type)
        return []
    endif

    if !has_key(s:file_template_map, a:type)
        " read local template file
        " if success then return template
        " else read plugin template file
        " if no success then set has no template and return empty lists
        if s:has_local_setting
            if <SID>InsertTemplate(a:type, s:local_template_dir)
                return s:file_template_map[a:type]
            endif
        endif

        if !<SID>InsertTemplate(a:type, s:template_dir)
            let s:filetype_no_template_map[a:type] = 1
            return []
        endif
    endif

    return s:file_template_map[a:type]
endfunction
" }}}

" s:InsertIgnoreFiletype {{{
function! s:InsertIgnoreFiletype()
    if s:has_init_ignore_filetype == 0
        let s:has_init_ignore_filetype = 1

        if exists("g:file_template_ignore_filetype")
            for suffix in g:file_template_ignore_filetype
                let s:filetype_no_template_map[suffix] = 1
            endfor
        endif
    endif
endfunction
" }}}

" s:InsertTemplateContent {{{
function! s:InsertTemplateContent()
    let l:type = &filetype
    if l:type == ""
        return
    endif

    call <SID>InitDynamicMacro()

    let l:lines = <SID>GetTemplate(l:type)
    let l:sub_macro_lines = []
    for line in l:lines
        let l:after_macro = line
        let l:keys = keys(s:macro_value_map)
        for k in l:keys
            let l:value = get(s:macro_value_map, k, '')
            let l:after_macro = substitute(l:after_macro, k, l:value, 'g')
        endfor
        call add(l:sub_macro_lines, l:after_macro)
    endfor
    call append(0, l:sub_macro_lines)
endfunction
" }}}

" s:InitLocalSetting {{{
function s:InitLocalSetting()
    if exists("g:local_template_dir") && 
                \g:local_template_dir != "" && 
                \isdirectory(expand(g:local_template_dir))

        let s:local_template_dir = fnamemodify(g:local_template_dir, ":p")
        let s:has_local_setting = 1

        let l:local_template_macro = s:local_template_dir . s:macro_file_name 
        if filereadable(l:local_template_macro)
            let s:template_macro = l:local_template_macro
        endif
    endif
endfunction
" }}}

call <SID>InitLocalSetting()
call <SID>InsertIgnoreFiletype()
call <SID>InitStaticMacro(s:template_macro)

augroup file_template
    au!
    autocmd BufNewFile * call <SID>InsertTemplateContent()
augroup END

