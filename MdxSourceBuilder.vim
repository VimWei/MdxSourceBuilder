" ======================================================
" MdxSourceBuilder 一键制作图片词典
" 原始词条 ==> 标准化词条 ==> mdx源文件 ==> mdx词典文件
" https://github.com/VimWei/MdxSourceBuilder
" ======================================================
"
" Quick Guide -------------------------------------------------------------{{{1
" 1. 准备好词条文件
" 2. 打开MdxSourceBuilder.vim，并配置好词典参数
" 3. 使用 :new 创建新文件，并执行 :bro so，找到 MdxSourceBuilder.vim
"    或者 :new 创建新文件，并执行 :so MdxSourceBuilder.vim
"
" Requirement -------------------------------------------------------------{{{1
" 1. 必须：安装Vim（官网下载 https://www.vim.org）
"    并在vimrc配置文件中添加一行 set encoding=utf-8
"    * 仅能输出CSS文件和mdx源文件
" 2. 可选：安装对应版本的python（官网下载 https://www.python.org）
"    可选：安装 mdict-utilis：pip install mdict-utils
"    * 能输出mdx和mdd词典文件
"
" 配置词典参数 ------------------------------------------------------------{{{1

" 拟输出的mdx源文件名称
let s:mdxSourceFileName = "火星词典.txt"

" CSS名称，其具体定义请查阅 MdxSourceBuilderCSS.vim
let g:CSSName = "MarsDict.css"

" 词典模块及其配置信息，格式如下：
" \[dictionaryPart, picNamePrefix, picFormat, PageKeywordStyle, KeywordsNavStyle],
let g:dictionaryParts = [
        \["火星词典.Cover.txt", "MarsDictCover_", ".png", 0, 1],
        \["火星词典.Prefix.txt", "MarsDictPrefix_", ".png", 0, 1],
        \["火星词典.Body.Part1.txt", "MarsDict_", ".png", 0, 2],
        \["火星词典.Body.Part2.txt", "MarsDict_", ".png", 1, 2],
        \["火星词典.Appendix.txt", "MarsDictAppendix_", ".png", 0, 1],
        \["火星词典.Pinyin.txt", "MarsDict_", ".png", 2, 0],
        \]
" dictionaryPart：词典各个模块的词条文件名称
" picNamePrefix：图片前缀名，不同词典模块通常会采用不同的前缀名
" picFormat：图片后缀名
" PageKeywordStyle：
" -若词条格式为'一行页码 + 多行关键词（每行一个关键词）'的标准词条格式，则设为0
" -若词条格式为'一个页码+多个中文单字符的关键词'的压缩词条格式，则设为1
" -若词条格式为'页码 + 分隔符 + 单个中或英关键词'的啰嗦行格式，则设为2
" 可根据需要自行修改MdxSourceBuilderCore.Vim，以添加各种兼容格式
" KeywordsNavStyle：根据需要定义Keywords导航样式
" - 若是拼音之类的辅助检索，建议设为0：自身没有页面和keywords导航，仅转LINK
" - 若是封面/附录之类的Affix，建议设为1：仅有页面导航，无keywords导航，简洁
" - 若是每页关键词很多的正文，建议设为2：不仅有页面导航，而且有keywords导航
" 可根据需要自行修改MdxSourceBuilderCore.Vim，以定义个性化的导航样式

" 补充更多的mdx源文件，比如@@@LINK文件
let s:anyMore = 1
let s:anyMoreMdxSource = "火星词典.Link.txt"

" 自定义固定链接的导航：\[链接名称, 链接目标图片名称],
let g:customNavList = [
            \["封面", "MarsDictCover_0001"],
            \["扉页", "MarsDictCover_0002"],
            \["版权", "MarsDictCover_0003"],
            \["获奖", "MarsDictCover_0006"],
            \["目录", "MarsDictPrefix_0001"],
            \["凡例", "MarsDictPrefix_0003"],
            \["上册", "MarsDict_0001"],
            \["下册", "MarsDict_0100"],
            \["附录", "MarsDictAppendix_0001"],
            \["封底", "MarsDictAppendix_0021"],
            \]

" 将.txt格式的mdx源文件打包为.mdx格式的词典文件
let s:autoMdxPack = 1
" 若设置为0，则不会输出.mdx词典文件，需要另行用MdxBuilder 3.x等工具手工打包
"   - 特点：mdx官方打包工具，对各种词典的兼容性最好
"   - 缺点：对大文件支持不够好；需要手工打包
" 若设置为1，则使用 mdict-utils 自动打包生成.mdx词典文件
"   - 特点：自动化、速度快、大词库、跨平台
"   - 缺点：需要安装如下软件，并配置信息
"       + 安装 与 Vim 匹配的 python 版本
"       + 安装 mdict-utilis：pip install mdict-utils

" 自动打包图片等资源到mdd
" 打包设为1，不打包则设为0
let s:autoMddPack = 0
" 图片等资源相对于词典所在的目录
let s:imageFolder = "images"

" 主程序 ------------------------------------------------------------------{{{1
" ==================================
" * 以下为主程序，适合高级用户定制 *
" ==================================

" 初始化 ------------------------------------------------------------------{{{2

" 防止自加载
if expand("%:p:t") == "MdxSourceBuilder.vim"
    echo "请先 :new 创建新文件，再执行 :so MdxSourceBuilder.vim"
    finish
endif

" 清空历史消息
messages clear

" 设置当前工作目录为本文档所在目录
let s:home = fnamemodify(resolve(expand('<sfile>:p')), ':h')
silent! exe 'cd ' . s:home
echomsg "已设置工作目录为：" . s:home

" 保存mdxSource文件
try
    silent! exe "write! " . s:mdxSourceFileName
catch
    silent! exe "bdelete! ". s:mdxSourceFileName
    silent! exe "write! " . s:mdxSourceFileName
endtry

" 重置info.title和info.description文件的编码为utf-8
if s:autoMdxPack == 1
    silent! set fileformat=unix
    silent! set nobomb
    silent! set fileencoding=utf-8
    " 设置info.title.html文件为utf-8格式
    silent! 0,$d
    silent! exe "read "
            \. substitute(s:mdxSourceFileName, ".txt$", ".info.title.html", "")
    silent! 0d
    try
        silent! exe "write! "
            \. substitute(s:mdxSourceFileName, ".txt$", ".info.title.html", "")
    catch
        silent! exe "bdelete! "
            \. substitute(s:mdxSourceFileName, ".txt$", ".info.title.html", "")
        silent! exe "write! "
            \. substitute(s:mdxSourceFileName, ".txt$", ".info.title.html", "")
    endtry
    " 设置info.description.html文件为utf-8格式
    silent! 0,$d
    silent! exe "read "
            \. substitute(s:mdxSourceFileName, ".txt$", ".info.description.html", "")
    silent! 0d
    try
        silent! exe "write! "
            \. substitute(s:mdxSourceFileName, ".txt$", ".info.description.html", "")
    catch
        silent! exe "bdelete! "
            \. substitute(s:mdxSourceFileName, ".txt$", ".info.description.html", "")
        silent! exe "write! "
            \. substitute(s:mdxSourceFileName, ".txt$", ".info.description.html", "")
    endtry
endif

" 输出CSS文件 -------------------------------------------------------------{{{2
silent! set fileformat=unix
silent! set nobomb
silent! set fileencoding=utf-8

" 输出CSS文件：若已打开，则先关闭旧的，再保存新的
silent! 0,$d
silent! exe "read ". "MdxSourceBuilderCSS.vim"
silent! 0d

try
    silent! exe "write! " . g:CSSName
catch
    silent! exe "bdelete! ". g:CSSName
    silent! exe "write! " . g:CSSName
endtry
silent! 0,$d
echomsg "已输出CSS，请查阅：" . getcwd() . "\\" . g:CSSName

" 输出MdxSource文件 -------------------------------------------------------{{{2
silent! set fileformat=dos
silent! set nobomb
silent! set fileencoding=utf-8

let g:mdxSource = ""
for dictionaryPart in g:dictionaryParts
    echomsg "正在处理：" . substitute(dictionaryPart[0], ".txt", "", "")
    silent! 0,$d
    silent! exe "read ". dictionaryPart[0]
    silent! 0d
    silent! source MdxSourceBuilderCore.vim
    silent! 0,$d
endfor
echomsg "正在生成 MdxSource 文件……"
let @x = g:mdxSource
silent! $put x

" 补充更多的Mdx源文件
if s:anyMore == 1
    silent! normal G
    silent! exe "read ". s:anyMoreMdxSource
endif

silent! global/^$/d
silent! write!
silent! noh

echomsg "已输出 MdxSource，请查阅: " . getcwd() . "\\" . s:mdxSourceFileName

" 输出mdx文件 -------------------------------------------------------------{{{2
" src: https://github.com/liuyug/mdict-utils

if s:autoMdxPack == 1
    echomsg "正在生成 Mdx 文件..."
    silent! exe "!mdict"
        \. " --title "
        \. substitute(s:mdxSourceFileName, ".txt$", ".info.title.html", "")
        \. " --description "
        \. substitute(s:mdxSourceFileName, ".txt$", ".info.description.html", "")
        \. " -a % "
        \. substitute(s:mdxSourceFileName, ".txt$", ".mdx", "")

    echomsg "已输出 Mdx，请查阅: " . getcwd() . "\\"
        \. substitute(s:mdxSourceFileName, ".txt$", ".mdx", "")
endif

if s:autoMddPack == 1
    echomsg "正在生成 Mdd 文件..."
    silent! exe "!mdict"
        \. " -a " . s:imageFolder . " "
        \. substitute(s:mdxSourceFileName, ".txt$", ".mdd", "")

    echomsg "已输出 Mdd，请查阅: " . getcwd() . "\\"
        \. substitute(s:mdxSourceFileName, ".txt$", ".mdd", "")
endif

finish
