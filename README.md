Created by:
Ming Bai

Script type:
Utility

### Description
![Demo](https://web.archive.org/web/20131110125157/http://files.myopera.com/mbbill/files/code_complete.gif)

It shows what this script can do.

In insert mode, when you type `<C-CR>` (default value of g:completekey) after function name with a `(` , function parameters will be append behind, use `<C-CR>` key again to switch between parameters.

This key is also used to complete code snippets.

NOTE:
I changed the default <Tab> completion key mapping to <C-CR> i.e., Ctrl+Enter because <Tab> completion conflicts with some other configurations and plugins like Supertab.

#### Example:
press `<C-CR>` after function name and `(`

    foo ( <C-CR>
  
becomes:

    foo ( `<first param>`,`<second param>` )
  
press `<tab>` after code template

    if <C-CR>
  
becomes:

    if( `<...>` )
    {
        `<...>`
    }

### Code Snippets

Custom snippet files can be used. The default file is
[my_snippets.vim](plugin/my_snippets.vim) and is loaded by default. To add
more custom snippet files (see [my_snippets.vim](plugin/my_snippets.vim) for
the structure), use one of the following variables in your vimrc:

``` viml
let g:user_defined_snippets = "snippets/custom_snippets.vim"
let g:user_defined_snippets = ["snippets/c_snippets.vim", "snippets/js_snippets.vim"]
```
