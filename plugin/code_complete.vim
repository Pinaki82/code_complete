"==================================================
" File:         code_complete.vim
" Brief:        function parameter complete, code snippets, and much more.
" Author:       Mingbai <mbbill AT gmail DOT com>
" Last Change:  2009-06-09 00:09:03
" Version:      2.9
" Modification: Modified by Pinaki Sekhar Gupta.
" Last Modified: 2013-06-14 Thu 01:25 AM.
"
" Install:      1. Put code_complete.vim to plugin
"                  directory, if you don't have cream Installed.
"                  Otherwise put the plugin right into $VIMRUNTIME
"                  and source it in your _vimrc like:
"                  :source $VIMRUNTIME/code_complete.vim
"                  :source $HOME/vimfiles/plugin/code_complete.vim
"               or,
"                  :source $HOME/.vim/plugin/code_complete.vim
"               2. Use the command below to create tags
"                  file including signature field.
"                  ctags -R --c-kinds=+pxfvtcdeglmnsu --c++-kinds=+pxfvtcdeglmnsu --languages=C,C++ --langmap=C:.c.h --langmap=C++:.C.h.c.cpp.hpp.c++.cc.cp.cxx.h++.hh.hp.hxx --fields=+iaSm --extra=+qf -f tags *
"                  In the working directory.
"                  And in the include directory use the following accordingly
"                  ctags --c-kinds=+pxfvtcdeglmnsu --c++-kinds=+pxfvtcdeglmnsu --languages=C,C++ --langmap=C:.c.h --langmap=C++:.C.h.c.cpp.hpp.c++.cc.cp.cxx.h++.hh.hp.hxx. --fields=+iaSm --extra=+qf -f tags *
"                  or,
"                  ctags -R --c-kinds=+pxfvtcdeglmnsu --c++-kinds=+pxfvtcdeglmnsu --languages=C,C++ --langmap=C:.c.h --langmap=C++:.C.h.c.cpp.hpp.c++.cc.cp.cxx.h++.hh.hp.hxx. --fields=+iaSm --extra=+qf -f tags *
"
"
" NOTE:
" I changed the default <Tab> completion key mapping to <C-CR> i.e., Ctrl+Enter because <Tab> completion conflicts with some other configurations and plugins like Supertab.
"
" Usage:
"       Remember: " C-CR means Ctrl-Enter
"           hotkey:
"               "<C-CR>" (default value of g:completekey)
"               Do all the jobs with this key, see
"           example:
"               press <C-CR> after function name and (
"                 foo ( <C-CR>
"               becomes:
"                 foo ( `<first param>`,`<second param>` )
"               press <C-CR> after code template
"                 if <C-CR>
"               becomes:
"                 if( `<...>` )
"                 {
"                     `<...>`
"                 }
"
"
"           variables:
"
"               g:disable_codecomplete
"                   Disable code_complete, default enabled.
"
"               g:completekey
"                   the key used to complete function
"                   parameters and key words.
"
"               g:rs, g:re
"                   region start and stop
"               you can change them as you like.
"
"               g:user_defined_snippets
"                   file name of user defined snippets.
"
"               g:CodeComplete_Ignorecase
"                   use ignore case for keywords.

"           key words:
"               see "templates" section.
"==================================================

if v:version < 700
    finish
endif

if exists("g:disable_codecomplete")
    finish
endif

" Variable Definitions: {{{1
" options, define them as you like in vimrc:
if !exists("g:completekey")
    let g:completekey = "<C-CR>"   "hotkey
endif

if !exists("g:rs")
    let g:rs = '`<'    "region start
endif

if !exists("g:re")
    let g:re = '>`'    "region stop
endif

if !exists("g:user_defined_snippets")
    let g:user_defined_snippets = ""
endif

" ----------------------------
let s:expanded = 0  "in case of inserting char after expand
let s:signature_list = []
let s:jumppos = -1
let s:doappend = 1

" Autocommands: {{{1
autocmd BufReadPost,BufNewFile * call CodeCompleteStart()

" Menus:
menu <silent>       &Tools.Code\ Complete\ Start          :call CodeCompleteStart()<CR>
menu <silent>       &Tools.Code\ Complete\ Stop           :call CodeCompleteStop()<CR>

" Function Definitions: {{{1

function! CodeCompleteStart()
    exec "silent! iunmap  <buffer> ".g:completekey
    exec "inoremap <buffer> ".g:completekey." <c-r>=CodeComplete()<cr><c-r>=SwitchRegion()<cr>"
endfunction

function! CodeCompleteStop()
    exec "silent! iunmap <buffer> ".g:completekey
endfunction

function! FunctionComplete(fun, last_char)
    let s:signature_list=[]
    let signature_word=[]
    let ftags=taglist("^".a:fun."$")
    if type(ftags)==type(0) || ((type(ftags)==type([])) && ftags==[])
        return ''
    endif
    let tmp=''
    if a:last_char == ')'
        let s:append_tail = ''
    else
        let s:append_tail = ')'
    endif
    for i in ftags
        if match(i.cmd,'^/\^.*\(\*'.a:fun.'\)\(.*\)\;\$/')>=0
            if match(i.cmd,'(\s*void\s*)')<0 && match(i.cmd,'(\s*)')<0
                    let tmp=substitute(i.cmd,'^/\^','','')
                    let tmp=substitute(tmp,'.*\(\*'.a:fun.'\)','','')
                    let tmp=substitute(tmp,'^[\){1}]','','')
                    let tmp=substitute(tmp,';\$\/;{1}','','')
                    let tmp=substitute(tmp,'\$\/','','')
                    let tmp=substitute(tmp,';','','')
                    let tmp=substitute(tmp,',',g:re.','.g:rs,'g')
                    " let tmp=substitute(tmp,'(\(.*\))',g:rs.'\1'.g:re.')','g')
                    let tmp=substitute(tmp,'(\(.*\))',g:rs.'\1'.g:re.s:append_tail,'g')
            else
                    let tmp=''
            endif
            if (tmp != '') && (index(signature_word,tmp) == -1)
                let signature_word+=[tmp]
                let item={}
                let item['word']=tmp
                let item['menu']=i.filename
                let s:signature_list+=[item]
            endif
        endif
        if has_key(i,'kind') && has_key(i,'name') && has_key(i,'signature')
            if (i.kind=='p' || i.kind=='f') && i.name==a:fun  " p is declare, f is definition
                if match(i.signature,'(\s*void\s*)')<0 && match(i.signature,'(\s*)')<0
                    let tmp=substitute(i.signature,',',g:re.','.g:rs,'g')
                    " let tmp=substitute(tmp,'(\(.*\))',g:rs.'\1'.g:re.')','g')
                    let tmp=substitute(tmp,'(\(.*\))',g:rs.'\1'.g:re.s:append_tail,'g')
                else
                    let tmp=''
                endif
                if (tmp != '') && (index(signature_word,tmp) == -1)
                    let signature_word+=[tmp]
                    let item={}
                    let item['word']=tmp
                    let item['menu']=i.filename
                    let s:signature_list+=[item]
                endif
            endif
        endif
    endfor
    if s:signature_list==[]
        " return ')'
        return s:append_tail
    endif
    if len(s:signature_list)==1
        return s:signature_list[0]['word']
    else
        call  complete(col('.'),s:signature_list)
        return ''
    endif
endfunction

function! ExpandTemplate(cword)
    "let cword = substitute(getline('.')[:(col('.')-2)],'\zs.*\W\ze\w*$','','g')
    if has_key(g:template,&ft)
      if ( exists('g:CodeComplete_Ignorecase') && g:CodeComplete_Ignorecase )
        if has_key(g:template[&ft],tolower(a:cword))
            let s:jumppos = line('.')
            return "\<c-w>" . g:template[&ft][tolower(a:cword)]
        endif
      else
        if has_key(g:template[&ft],a:cword)
            let s:jumppos = line('.')
            return "\<c-w>" . g:template[&ft][a:cword]
        endif
      endif
    endif
    if ( exists('g:CodeComplete_Ignorecase') && g:CodeComplete_Ignorecase )
      if has_key(g:template['_'],tolower(a:cword))
          let s:jumppos = line('.')
          return "\<c-w>" . g:template['_'][tolower(a:cword)]
      endif
    else
      if has_key(g:template['_'],a:cword)
          let s:jumppos = line('.')
          return "\<c-w>" . g:template['_'][a:cword]
      endif
    endif
    return ''
endfunction

function! SwitchRegion()
    if len(s:signature_list)>1
        let s:signature_list=[]
        return ''
    endif
    if s:jumppos != -1
        call cursor(s:jumppos,0)
        let s:jumppos = -1
    endif
    if match(getline('.'),g:rs.'.*'.g:re)!=-1 || search(g:rs.'.\{-}'.g:re)!=0
        normal 0
        call search(g:rs,'c',line('.'))
        normal v
        call search(g:re,'e',line('.'))
        if &selection == "exclusive"
            exec "norm l"
        endif
        return "\<c-\>\<c-n>gvo\<c-g>"
    else
        if s:doappend == 1
            if g:completekey == "<C-CR>"
                return "\<C-CR>"
            endif
        endif
        return ''
    endif
endfunction

function! CodeComplete()
    let s:doappend = 1
    let function_name = matchstr(getline('.')[:(col('.')-2)],'\zs\w*\ze\s*(\s*$')
    if function_name != ''
        let funcres = FunctionComplete(function_name, getline('.')[col('.')-1])
        if funcres != ''
            let s:doappend = 0
        endif
        return funcres
    else
        let template_name = substitute(getline('.')[:(col('.')-2)],'\zs.*\W\ze\w*$','','g')
        let tempres = ExpandTemplate(template_name)
        if tempres != ''
            let s:doappend = 0
        endif
        return tempres
    endif
endfunction


" [Get converted file name like __THIS_FILE__ ]
function! GetFileName()
    let filename=expand("%:t")
    let filename=toupper(filename)
    let _name=substitute(filename,'\.','_',"g")
    "let _name="__"._name."__"
    return _name
endfunction

" Templates: {{{1
" to add templates for new file type, see below
"
" "some new file type
" let g:template['newft'] = {}
" let g:template['newft']['keyword'] = "some abbrevation"
" let g:template['newft']['anotherkeyword'] = "another abbrevation"
" ...
"
" ---------------------------------------------
" C templates
let g:template = {}
let g:template['c'] = {}
let g:template['c']['cc'] = "/*  */\<left>\<left>\<left>"
let g:template['c']['cd'] = "/**<  */\<left>\<left>\<left>"
let g:template['c']['de'] = "#define  ".g:rs."MACRO_TEMPLATE_DEFINITION_UPPERCASE_ONLY(_with,_arguments,_small,_case)".g:re."  ".g:rs."macro_expansion_value_(or_math_expression)".g:re.""
let g:template['c']['in'] = "#include    \"\"\<left>"
let g:template['c']['is'] = "#include  <>\<left>"
let g:template['c']['ff'] = "#ifndef  __\<c-r>=GetFileName()\<cr>__\<CR>#define  __\<c-r>=GetFileName()\<cr>__".
            \repeat("\<cr>",5)."#endif  /* __\<c-r>=GetFileName()\<cr>__ */".repeat("\<up>",3)
let g:template['c']['for'] = "for( ".g:rs."...".g:re." ; ".g:rs."...".g:re." ; ".g:rs."...".g:re." )\<cr>{\<cr>".
            \g:rs."...".g:re."\<cr>}\<cr>"
let g:template['c']['main'] = "int main(int argc, char \*argv\[\])\<cr>{\<cr>".g:rs."...".g:re."\<cr>}"
let g:template['c']['switch'] = "switch ( ".g:rs."...".g:re." )\<cr>{\<cr>case ".g:rs."...".g:re." :\<cr>break;\<cr>case ".
            \g:rs."...".g:re." :\<cr>break;\<cr>default :\<cr>break;\<cr>}"
let g:template['c']['if'] = "if( ".g:rs."...".g:re." )\<cr>{\<cr>".g:rs."...".g:re."\<cr>}"
let g:template['c']['while'] = "while( ".g:rs."...".g:re." )\<cr>{\<cr>".g:rs."...".g:re."\<cr>}"
let g:template['c']['ife'] = "if( ".g:rs."...".g:re." )\<cr>{\<cr>".g:rs."...".g:re."\<cr>}\<cr>else\<cr>{\<cr>".g:rs."...".
            \g:re."\<cr>}"
"
" Additional C templates
"
let g:template['c']['case'] = "\<cr>case ".g:rs."...".g:re." :\<cr>break;\<cr>"
let g:template['c']['printf'] = "printf( \"".g:rs."...".g:re."\\n\" );\<left>\<left>"
let g:template['c']['scanf'] = "scanf( \"%".g:rs."...".g:re."  %".g:rs."...".g:re."\", ".g:rs."&".g:re."".g:rs."...".g:re.", ".g:rs."&".g:re."".g:rs."...".g:re." );\<left>\<left>"
let g:template['c']['do'] = "do {\<cr> ".g:rs."...".g:re." \<cr>} while ( ".g:rs."...".g:re." );\<cr>"
let g:template['c']['elf'] = "else if ( ".g:rs."...".g:re." )\<cr>{\<cr>".g:rs."...".g:re."\<cr>}\<cr>\<Space>\<BS>"
let g:template['c']['else'] = "else\<cr>{\<cr>".g:rs."...".g:re."\<cr>}\<cr>"
let g:template['c']['fin'] = "fflush(stdin);\<cr>\<right>"
let g:template['c']['system'] = "system(\"".g:rs."...".g:re."\");\<left>\<left>"
let g:template['c']['TODO'] = "/* TODO: ".g:rs."...".g:re." */\<left>\<left>\<left>"
let g:template['c']['FIXME'] = "/* FIXME: ".g:rs."...".g:re." */\<left>\<left>\<left>"
let g:template['c']['NOTE'] = "/* NOTE: ".g:rs."...".g:re." */\<left>\<left>\<left>"
let g:template['c']['XXX'] = "/* XXX: ".g:rs."...".g:re." */\<left>\<left>\<left>"
let g:template['c']['enum'] = "enum ".g:rs."function_name".g:re." {\<cr>".g:rs."...".g:re."\<cr>}; /* --- end of enum ".g:rs."function_name".g:re." --- */\<cr>\<left>\<cr>typedef enum ".g:rs."function_name".g:re." ".g:rs."Function_name".g:re.";"
let g:template['c']['struct'] = "struct ".g:rs."srtucture_name".g:re." {\<cr>".g:rs."...".g:re."\<cr>}; /* --- end of struct ".g:rs."srtucture_name".g:re." --- */\<cr>\<left>\<cr>typedef struct ".g:rs."srtucture_name".g:re." ".g:rs."Srtucture_name".g:re.";"
let g:template['c']['union'] = "union ".g:rs."union_name".g:re." {\<cr>".g:rs."...".g:re."\<cr>}; /* --- end of union ".g:rs."union_name".g:re." --- */\<cr>\<left>\<cr>typedef union ".g:rs."union_name".g:re." ".g:rs."Union_name".g:re.";"
let g:template['c']['calloc'] = "".g:rs."int/char/float/TYPE *pointer;".g:re."\<cr>\<Space>\<BS>\<cr>".g:rs."pointer".g:re." = (".g:rs."int/char/float/TYPE".g:re."  *)calloc ( (size_t)(".g:rs."COUNT".g:re."), sizeof(".g:rs."TYPE".g:re.") );\<cr>if ( ".g:rs."pointer".g:re."==NULL ) {\<cr>fprintf ( stderr, \"\\ndynamic memory allocation failed\\n\");\<cr>exit (EXIT_FAILURE);\<cr>}\<cr>free (".g:rs."pointer".g:re.");\<cr>".g:rs."pointer".g:re."	= NULL;\<cr>"
let g:template['c']['malloc'] = "".g:rs."int/char/float/TYPE *pointer;".g:re."\<cr>\<Space>\<BS>\<cr>".g:rs."pointer".g:re." = (".g:rs."int/char/float/TYPE".g:re."  *)malloc (".g:rs." (size_t)COUNT_if_needed  *  ".g:re." sizeof (".g:rs."TYPE".g:re.") );\<cr>if ( ".g:rs."pointer".g:re."==NULL ) {\<cr>fprintf ( stderr, \"\\ndynamic memory allocation failed\\n\");\<cr>exit (EXIT_FAILURE);\<cr>}\<cr>free (".g:rs."pointer".g:re.");\<cr>".g:rs."pointer".g:re."	= NULL;\<cr>"
let g:template['c']['free'] = "free (".g:rs."pointer".g:re.");\<cr>".g:rs."pointer".g:re."	= NULL;\<cr>"
let g:template['c']['realloc'] = "".g:rs."pointer".g:re." = realloc (  ".g:rs."pointer".g:re.", sizeof (".g:rs."TYPE".g:re.") );\<cr>if ( ".g:rs."pointer".g:re."==NULL ) {\<cr>fprintf ( stderr, \"\\ndynamic memory allocation failed\\n\");\<cr>exit (EXIT_FAILURE);\<cr>}\<cr>"
let g:template['c']['sizeof'] = "sizeof (".g:rs."TYPE".g:re.")"
let g:template['c']['assert'] = "assert (".g:rs."...".g:re.");\<cr>"
let g:template['c']['filein'] = "FILE	*".g:rs."input-file".g:re.";      /* input-file pointer */\<cr>\<Space>\<BS>\<cr>char	*".g:rs."input-file".g:re."_file_name = \"".g:rs."...".g:re."\";      /* input-file name */ /* use extension within double quotes */\<cr>\<Space>\<BS>\<cr>\<cr>".g:rs."input-file".g:re."	= fopen( ".g:rs."input-file".g:re."_file_name, \"r\" );\<cr>if ( ".g:rs."input-file".g:re."==NULL ) {\<cr>fprintf ( stderr, \"\\ncouldn't open file '%s'; %s\\n\", ".g:rs."input-file".g:re."_file_name,  strerror(errno) );\<cr>exit (EXIT_FAILURE);\<cr>}\<cr>\<cr>else if ( ".g:rs."input-file".g:re."!=NULL ) {\<cr>fprintf ( stderr, \"\\nopened file '%s'; %s\\n\", ".g:rs."input-file".g:re."_file_name,  strerror(errno) );\<cr>\<cr>".g:rs."-continue_here-".g:re."\<cr>\<cr>if ( fclose (".g:rs."input-file".g:re.")==EOF )  {  /* close input file */\<cr>fprintf ( stderr, \"\\ncouldn't close file '%s'; %s\\n\", ".g:rs."input-file".g:re."_file_name,  strerror(errno) );\<cr>exit (EXIT_FAILURE);\<cr>}\<cr>}"
let g:template['c']['fileout'] = "FILE	*".g:rs."output-file".g:re.";      /* output-file pointer */\<cr>\<Space>\<BS>\<cr>char	*".g:rs."output-file".g:re."_file_name = \"".g:rs."...".g:re."\";      /* output-file name */ /* use extension within double quotes */\<cr>\<Space>\<BS>\<cr>\<cr>".g:rs."output-file".g:re."	= fopen( ".g:rs."output-file".g:re."_file_name, \"w\" );\<cr>if ( ".g:rs."output-file".g:re."==NULL ) {\<cr>fprintf ( stderr, \"\\ncouldn't open file '%s'; %s\\n\", ".g:rs."output-file".g:re."_file_name,  strerror(errno) );\<cr>exit (EXIT_FAILURE);\<cr>}\<cr>\<cr>else if ( ".g:rs."output-file".g:re."!=NULL ) {\<cr>fprintf ( stderr, \"\\nopened file '%s'; %s\\n\", ".g:rs."output-file".g:re."_file_name,  strerror(errno) );\<cr>\<cr>".g:rs."-continue_here-".g:re."\<cr>\<cr>if ( fclose (".g:rs."output-file".g:re.")==EOF )  {  /* close output file */\<cr>fprintf ( stderr, \"\\ncouldn't close file '%s'; %s\\n\", ".g:rs."output-file".g:re."_file_name,  strerror(errno) );\<cr>exit (EXIT_FAILURE);\<cr>}\<cr>}"
let g:template['c']['fprintf'] = "fprintf ( ".g:rs."file-pointer".g:re.",  \"\\n\",  ".g:rs."...".g:re."  );\<left>\<left>"
let g:template['c']['fscanf'] = "fscanf ( ".g:rs."file-pointer".g:re.",  \"".g:rs."...".g:re."\",  &".g:rs."...".g:re."  );\<left>\<left>"
let g:template['c']['in1'] = "#include <errno.h>\<cr>#include <stdint.h>\<cr>#include <math.h>\<cr>#include <stdio.h>\<cr>#include <stdlib.h>\<cr>#include <string.h>\<cr>#include <".g:rs."...".g:re.">\<cr>#include <".g:rs."...".g:re.">\<cr>#include \"".g:rs."...".g:re."\"\<cr>#include \"".g:rs."...".g:re."\"\<cr>"
let g:template['c']['ffc'] = "#ifndef  __\<c-r>=GetFileName()\<cr>__\<CR>#define  __\<c-r>=GetFileName()\<cr>__".
            \repeat("\<cr>",2).
            \"\<cr>".g:rs."MACRO, global variables, etc..".g:re."\<cr>".
            \repeat("\<cr>",2)."#include <errno.h>\<cr>#include <math.h>\<cr>#include <stdio.h>\<cr>#include <stdlib.h>\<cr>#include <string.h>\<cr>#include <".g:rs."...".g:re.">\<cr>#include <".g:rs."...".g:re.">\<cr>#include \"".g:rs."...".g:re."\"\<cr>#include \"".g:rs."...".g:re."\"\<cr>".
            \"\<cr>#ifdef __cplusplus\<cr>extern \"C\"\<cr>{\<cr>#endif\<cr>".
            \"\<cr>".g:rs."function prototype".g:re."\<cr>".
            \repeat("\<cr>",3)."#ifdef __cplusplus\<cr>}\<cr>#endif\<cr>".
            \"\<cr>#endif  /* __\<c-r>=GetFileName()\<cr>__ */".repeat("\<cr>",7).repeat("\<up>",3)
let g:template['c']['def'] = "defined( ".g:rs."...".g:re." )"
let g:template['c']['und'] = "#undef ".g:rs."...".g:re.""
let g:template['c']['ifm'] = "#if  ".g:rs."conditions like ||, &&, !, !=, <, >, <=, >= etc. can be used only with #if and #elif macro".g:re."\<cr>       ".g:rs."...".g:re."\<cr>#endif"
let g:template['c']['er'] = "#error  \"".g:rs."write everything within double_quotes".g:re."\""
let g:template['c']['ifd'] = "#ifdef  ".g:rs."...".g:re."\<cr>       ".g:rs."...".g:re."\<cr>#endif"
let g:template['c']['ifn'] = "#ifndef  ".g:rs."...".g:re."\<cr>       ".g:rs."...".g:re."\<cr>#endif"
let g:template['c']['elm'] = "#else\<cr>       ".g:rs."Take_the_Steps_after_#else..".g:re.""
let g:template['c']['eli'] = "#elif ".g:rs."conditions like ||, &&, !, !=, <, >, <=, >= etc. can be used with this macro, since #if is associated".g:re.""
let g:template['c']['en'] = "#endif"
let g:template['c']['lin'] = "#line ".g:rs."...".g:re.""
let g:template['c']['pra'] = "#pragma  ".g:rs."...".g:re.""
" ---------------------------------------------
" C++ templates
let g:template['cpp'] = g:template['c']
"
" Additional C templates
"
let g:template['cpp']['usi'] = "using namespace ".g:rs."std".g:re.";"
let g:template['cpp']['in2'] = "#include <cerrno>\<cr>#include <iostream>\<cr>#include <vector>\<cr>#include <ios>\<cr>#include <ostream>\<cr>#include <string>\<cr>#include <cmath>\<cr>#include <cstdio>\<cr>#include <cstdlib>\<cr>#include <".g:rs."...".g:re.">\<cr>#include <".g:rs."...".g:re.">\<cr>#include \"".g:rs."...".g:re."\"\<cr>#include \"".g:rs."...".g:re."\"\<cr>"
let g:template['cpp']['cout'] = "std::cout << ".g:rs."...".g:re." << std::endl;"
let g:template['cpp']['cin1'] = "std::cin >> ".g:rs."...".g:re.";"
let g:template['cpp']['cin2'] = "std::cin.".g:rs."...".g:re.";"
" ---------------------------------------------
" common templates
let g:template['_'] = {}
let g:template['_']['xt'] = "\<c-r>=strftime(\"%Y-%m-%d %H:%M:%S\")\<cr>"

" ---------------------------------------------
" load user defined snippets
exec "silent! runtime plugin/my_snippets.vim"
if type(g:user_defined_snippets) == type("")
  exec "silent! runtime ".g:user_defined_snippets
  exec "silent! source ".g:user_defined_snippets
elseif type(g:user_defined_snippets) == type([])
  for snippet in g:user_defined_snippets
    exec "silent! runtime ".snippet
    exec "silent! source ".snippet
  endfor
endif

" vim: set fdm=marker et :
