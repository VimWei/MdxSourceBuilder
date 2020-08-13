"===================================================
" Essential settings by VimWei
"===================================================

" Basic Setting -----------------------------------------------------------{{{1
set nocompatible    "启用不兼容Vi模式
syntax on
filetype plugin indent on   "文件类型自动识别，并使用相关插件和自动缩进

" Encoding related --------------------------------------------------------{{{1
set encoding=utf-8  "Vim 内部工作编码
set fileencoding=utf-8  "设置此缓冲区所在文件的字符编码；新文件默认编码
" 打开文件时自动尝试下面顺序的编码
set fileencodings=ucs-bom,utf-8,cp936,gb18030,big5,euc-jp,euc-kr,latin1
source $VIMRUNTIME/delmenu.vim
set langmenu=zh_CN.UTF-8    "指定菜单语言，若需要英文则none
source $VIMRUNTIME/menu.vim
language message zh_CN.UTF-8    "指定提示信息语言，英语为 en_US.ISO_8859-1
set ambiwidth=double    "使用US-ASCII字符两倍的宽度显示宽度不明的字符
set nobomb    "取消UTF的BOMB文件头
set ffs=unix,dos,mac    " 文件换行符，默认使用 unix 换行符
set cm=blowfish2    "设置新的加密算法

" CD ----------------------------------------------------------------------{{{1
" 命令行中将 %% 展开为活动缓冲区所在目录的路径，相当于 %:h<Tab>
cnoremap <expr> %% getcmdtype( ) == ':' ? expand('%:p:h').'/' : '%%'

" 改变当前工作目录为当前缓冲区所在的目录
command! CD cd %:p:h

" 快速进入当前缓冲区所在目录
map <leader>ew :<C-u>e %%
map <leader>es :<C-u>sp %%
map <leader>ev :<C-u>vsp %%
map <leader>et :<C-u>tabe %%

" Display related ---------------------------------------------------------{{{1
set helplang=cn "帮助语言首选中文版，可通过@en切换为英文
set scrolloff=0 "光标移动到buffer的顶部和底部时保持u行距离
set number  "在每行前面显示行号
set relativenumber  "显示相对于光标所在的行的行号
set ruler   "总在Vim窗口的右下角显示当前光标位置
set cursorline  "高亮光标所在的屏幕行
set showcmd "在Vim窗口右下角，标尺的右边显示未完成的命令
set display=lastline    "窗口末行内容较多时，尽量显示内容而非@@@

" statusline --------------------------------------------------------------{{{1
set laststatus=2                                " 总是显示状态栏
set statusline=                                 " 清空状态
set statusline+=\[B%n]                          " buffer编号
set statusline+=\ %f                            " 文件名
set statusline+=\ %m                            " 编辑状态
set statusline+=%=                              " 向右对齐
set statusline+=\ %y                            " 文件类型
" 最右边显示文件编码和行号等信息，并且固定在一个 group 中，优先占位
set statusline+=\ %0(%{&fileformat}\ [%{(&fenc==\"\"?&enc:&fenc).(&bomb?\",BOM\":\"\")}]\ %v:%l/%L=%p%%%)

" Format related ----------------------------------------------------------{{{1
set textwidth=0    "光标超过指定列的时候折行
set wrap    "自动折行，超过窗口宽度的行会回绕，并在下一行继续显示
set linebreak   "不在单词中间断行
set formatoptions+=m    " 如遇Unicode值大于255的文本，不必等到空格再折行
set formatoptions+=B    " 合并两行中文时，不在中间加空格

" Tab related -------------------------------------------------------------{{{1
set tabstop=4   "Tab所占用的空格数量
set shiftwidth=4   "自动缩进所占用的空格数量
set shiftround  "缩进取整到'shiftwidth'的倍数
set expandtab   "编辑时将所有Tab替换为空格
set smarttab    "行首Tab插入shiftwidth空格，按一次Backspace删除所有空格
set autoindent  "普通文件类型的自动缩进，开启新行时，从当前行复制缩进

" Editing related ---------------------------------------------------------{{{1
set history=1000    "命令历史的保存数量
set clipboard=unnamed   "与系统共享剪贴板
" 允许在自动缩进、换行符、插入开始的位置上退格
set backspace=indent,eol,start
" 对某一个或几个按键开启到头后自动折向下一行的功能
set whichwrap=b,s,<,>,[,]
set wildmenu    "命令行补全时，使用增强的单行菜单形式显示补全内容
set browsedir=buffer    "浏览启动目录使用当前缓冲区所在目录
set autoread    "自动重新读入被修改的文件
set mouse=a "在所有模式下允许使用鼠标
set mousemodel=popup
set selectmode= "不使用选择模式
set keymodel=   "不使用“Shift + 方向键”选择文本
set selection=inclusive "指定在选择文本时，光标所在位置也属于被选中的范围

" Search related ----------------------------------------------------------{{{1
set path+=**    "Search down into subfolders, :find and etc.
set ignorecase  "忽略大小写敏感
set smartcase   "智能大小写：以小写开头则不敏感，以大写开头则敏感
set showmatch   "高亮显示匹配的括号
set matchtime=2 "显示配对括号的十分之一秒数
set incsearch   "在未完全输入完毕要搜索的文本时就显示相应的匹配点
set hlsearch    "高亮显示所有匹配的搜索结果
