" 读取词典参数 ------------------------------------------------------------{{{1
let s:CSSName = g:CSSName
let s:pageNumDigit = '%0'. g:pageNumDigit . 'd'
let s:sourceStyle = anyMoreSource[1]
let s:pagePrefix = anyMoreSource[2]

" 初始化及通用函数定义 ----------------------------------------------------{{{1
" 清理并保存，以便后续代码可以正常运作
silent! normal! Go
silent! global/^"/d
silent! global/^$/d
silent! w!

function! StandardizeStyle(sourceStyle)
    " 将 page,keywords 输入文件格式整理为标准格式
    if a:sourceStyle == 0
        " No further treatment is required
        " 适合如下标准词条格式：一行页码 + 多行关键词（每行一个关键词）
        " 0001
        " a
        " b
        " c
        " 0002
        " x
        " y
        " z
    elseif a:sourceStyle == 1
        " 适合如下词条格式：行格式为'一个页码+多个中文单字符的关键词'
        " 0001吖阿啊锕腌啊嗄啊哎
        " 0002哀埃挨唉锿挨皑癌毐欸嗳矮蔼
        " 0003霭艾砹唉爱隘碍嗳嗌媛瑷
        " 以下将的单行格式转换为标准词条格式
        " 将页码换行
        silent! %s/^\d\{3,}\($\)\@!/\0\r/e
        " 将每个字独立成行
        silent! %s/\D\($\)\@!/\0\r/ge
    elseif a:sourceStyle == 2
        " 适合如下词条格式：行格式为"页码 + 分隔符 + 单个中或英关键词"
        " 分隔符兼容：Tab键'\t', 4个及以上空格'\s\{4,}'
        " 0001    abandon
        " 0001    abandoned
        " 0002    abandonee
        " 0002    a bas
        " 0003    abdominous
        " 将所有Tab替换为空格
        silent! set expandtab tabstop=4 | %retab
        normal gg
        let linenumber = printf(s:pageNumDigit, 0)
        for line in getline(1,'$')
            let words = split(line, '\s\{4,}')
            if linenumber == words[0]
                silent! s/^.*$/\= words[1]/e
            else
                let linenumber = words[0]
                silent! s/^.*$/\= words[0] . "\n". get(words, 1, "")/e
            endif
            silent! normal j
        endfor
    elseif a:sourceStyle == 3
        " 适合如下词条格式：行格式为"单个中或英关键词 + 分隔符 + 页码"
        " 分隔符兼容：Tab键'\t', 4个及以上空格'\s\{4,}'
        " abandon    0001
        " abandoned    0001
        " abandonee    0002
        " a bas    0002
        " abdominous    0003
        " 将所有Tab替换为空格
        silent! set expandtab tabstop=4 | %retab
        " 将格式转为sourceStyle 2
        silent! %s/^\(.\{-}\)\s\{4,}\(\d\{3,}\)$/\2    \1/
        normal gg
        let linenumber = printf(s:pageNumDigit, 0)
        for line in getline(1,'$')
            let words = split(line, '\s\{4,}')
            if linenumber == words[0]
                silent! s/^.*$/\= words[1]/e
            else
                let linenumber = words[0]
                silent! s/^.*$/\= words[0] . "\n". get(words, 1, "")/e
            endif
            silent! normal j
        endfor
    else
        echomsg "警告！未定义 SourceStyle " . a:sourceStyle . " 的标准化方案！"
    endif
    " 清理并保存，以便后续代码可以正常运作
    silent! normal! Go
    silent! %s/?/？/g
    silent! global/^$/d
    silent! w!
endfunction

function! PageList()
    " 创建、排序、去重 pageList
    let s:pageList = []
    global/^\d\{3,}$/call add(s:pageList, str2nr(getline('.')))
    let s:pageList = uniq(sort(s:pageList,'n'))
    return s:pageList
    " echomsg s:pageList
endfunction

function! KeywordsDict()
    let startline = line(".")
    let currentPage = str2nr(getline('.'))

    silent! cbelow
    let endline = line(".")
    let lastline = line("$")

    if endline == startline
        if endline == lastline
            silent! let s:keywordsDict[currentPage]
                        \= get(s:keywordsDict, currentPage, [])
                        \+ getline(startline+1, endline-1)
        else
            silent! let s:keywordsDict[currentPage]
                        \= get(s:keywordsDict, currentPage, [])
                        \+ getline(startline+1, lastline)
        endif
    else
        silent! let s:keywordsDict[currentPage]
                    \= get(s:keywordsDict, currentPage, [])
                    \+ getline(startline+1, endline-1)
        silent! cabove
    endif
    return s:keywordsDict
endfunction

function! KeywordsDicts()
    let s:keywordsDict = {}
    silent! vimgrep /^\d\{3,}$/ %
    silent! cdo call KeywordsDict()
    " echomsg s:keywordsDict
endfunction

" 根据SourceStyle输出标准的mdx源文件格式 ----------------------------------{{{1
if index([0,1,2,3], s:sourceStyle) >= 0
    " 运行初始化函数
    silent! call StandardizeStyle(s:sourceStyle)
    silent! call PageList()
    silent! call KeywordsDicts()
    " 清空全文
    silent! %delete
    " 将标准化词条转为标准的mdx源文件格式
    for currentPage in s:pageList
        for currentKeyword in s:keywordsDict[currentPage]
            silent! let s:atLink = [currentKeyword
                \, '@@@LINK=' . s:pagePrefix
                \. printf(s:pageNumDigit, currentPage)
                \, '</>']
            silent! call append('$', s:atLink)
        endfor
    endfor
elseif s:sourceStyle == 104
    " 将带有编号的主词条改造为使用"s+编号"进行检索
    silent! %s/^\(\d*\)\(\s.*\)$/s\1\r@@@LINK=\0\r<\/>/
elseif s:sourceStyle == 105
    " 运行初始化函数
    silent! call StandardizeStyle(s:sourceStyle)
    silent! call PageList()
    silent! call KeywordsDicts()
    " 清空全文
    silent! 0,$d
    " 将标准化词条转为标准的mdx源文件格式
    for currentPage in s:pageList
        for currentKeyword in s:keywordsDict[currentPage]
            " 对currentKeyword进行特殊处理
            silent! let s:atLink = [currentKeyword
                \, '@@@LINK=' . s:pagePrefix
                \. printf(s:pageNumDigit, currentPage)
                \, '</>'
                \, "s" . split(currentKeyword, '\s')[0]
                \, '@@@LINK=' . currentKeyword
                \, '</>']
            silent! call append('$', s:atLink)
        endfor
    endfor
elseif s:sourceStyle == 106
    " 1. “中英文”定位到页面
    let lineDicts = {}
    let lineNumber = 0
    for line in getline(1,'$')
        let lineDicts[lineNumber] = split(line, '\s\{4,}')
        let lineNumber += 1
    endfor
    " 清空全文
    silent! 0,$d
    for line in range(lineNumber)
        let lineList = lineDicts[line]
        silent! let s:atLink = [lineList[2]
            \, '@@@LINK=' . s:pagePrefix
            \. lineList[0]
            \, '</>'
            \, lineList[1]
            \, '@@@LINK=' . lineList[2]
            \, '</>'
            \, lineList[3]
            \, '@@@LINK=' . lineList[2]
            \, '</>']
        silent! call append('$', s:atLink)
    endfor
elseif s:sourceStyle == 107
    " 添加编号链接
    silent! %s/\(\d\+\)/<a href="entry:\/\/s\1">\1<\/a>/g
    " 给每个词条添加CSS
    silent! execute '%s/^\(<\/>\)/'
                \. '<link rel="stylesheet" type="text\/css" href="'
                \. s:CSSName
                \. '" \/>\r\0/e'
elseif s:sourceStyle == 109
    " 基于888改造：主词条为页码
    silent! g/^\s*"/d
    silent! global/^$/d
    silent! %s/?/？/g
    silent! set expandtab tabstop=4 | %retab
    silent! w!
    let lineDicts = {}
    let lineNumber = 0
    for line in getline(1,'$')
        let lineDicts[lineNumber] = split(line, '\s\{4,}')
        let lineNumber += 1
    endfor
    silent! %delete
    for line in range(lineNumber)
        let lineList = lineDicts[line]
        for dictKeyword in lineList[1:]
            silent! let s:atLink = [dictKeyword
                        \, '@@@LINK=' . s:pagePrefix . lineList[0]
                        \, '</>']
            silent! call append('$', s:atLink)
        endfor
    endfor
elseif s:sourceStyle == 888
    " 适用于快速手工添加链接词条
    " 词条格式：现有关键词\t链接词条1\t链接词条2\t链接词条3
    " 分隔符兼容Tab和空格(4位及以上)
    " 可以添加注释行：与VimL一样，以 " 开头
    " 可以添加空行
    " ///////////////
    " 清理数据：删除注释行、空行、问号中文化、Tab转空格
    silent! g/^\s*"/d
    silent! global/^$/d
    silent! %s/?/？/g
    silent! set expandtab tabstop=4 | %retab
    silent! w!
    let lineDicts = {}
    let lineNumber = 0
    for line in getline(1,'$')
        let lineDicts[lineNumber] = split(line, '\s\{4,}')
        let lineNumber += 1
    endfor
    silent! 0,$d
    for line in range(lineNumber)
        let lineList = lineDicts[line]
        for dictKeyword in lineList[1:]
            silent! let s:atLink = [dictKeyword
                        \, '@@@LINK=' . lineList[0]
                        \, '</>']
            silent! call append('$', s:atLink)
        endfor
    endfor
elseif s:sourceStyle == 998
    " 清理数据：删除注释行、空行
    " 注释行：与VimL一样，以 " 开头
    silent! g/^\s*"/d
    silent! global/^$/d
    silent! w!
    " 给每个词条添加CSS
    silent! execute '%s/^\(<\/>\)/'
                \. '<link rel="stylesheet" type="text\/css" href="'
                \. s:CSSName
                \. '" \/>\r\0/e'
elseif s:sourceStyle == 999
    " 清理数据：删除注释行、空行
    " 注释行：与VimL一样，以 " 开头
    silent! g/^\s*"/d
    silent! global/^$/d
    silent! w!
    " No further treatment is required
else
    echomsg "警告！！未定义 SourceStyle " . s:sourceStyle . " 的处理方案！"
endif

" 将输出结果保存到mdxSource  ----------------------------------------------{{{1
silent! global/^$/d
let g:mdxSource = extend(g:mdxSource, getline(1, "$"))

" Reference  --------------------------------------------------------------{{{1
finish

" 在新Tab页打开output文件
silent! tabe %:r.output.%:e

/* vim: set et sw=4 ts=4 sts=4 fdm=marker ff=unix ft=vim fenc=utf8 nobomb: */
