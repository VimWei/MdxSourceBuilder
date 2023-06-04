" 读取词典参数 ------------------------------------------------------------{{{1
let s:CSSName = g:CSSName
let s:pageNumDigit = '%0'. g:pageNumDigit . 'd'
let s:customNavList = g:customNavList
let s:picNamePrefix = g:multiLevelParts[1]
let s:picFormat = g:multiLevelParts[2]
let s:navStyle =  g:multiLevelParts[3]

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

function! StandardizeMultiFiles()
    let i = 0
    let s:multiFileStd = {}
    for multiFile in g:multiLevelParts[0]
        " 读取每个文件
        silent! exe "$read ". multiFile[0]
        let sourceStyle = multiFile[1]
        " 标准化每个文件
        silent! call StandardizeStyle(sourceStyle)
        " 将每个文件都存入字典 s:multiFileStd
        let s:multiFileStd[i] = getline(1, "$")
        silent! %delete
        let i += 1
    endfor
    return s:multiFileStd
    " 监测：输出变量
    " echomsg s:multiFileStd
    " silent! call append('$', s:multiFileStd)
    " silent! call append('$', s:multiFileStd[0])
    " for i in keys(s:multiFileStd)
    "     silent! call append('$', s:multiFileStd[i])
    " endfor
endfunction

function! PageList()
    silent! %delete
    for i in keys(s:multiFileStd)
        " 加载已经标准化的multiFileStd
        silent! call append('$', s:multiFileStd[i])
    endfor
    " 创建、排序、去重 pageList
    let s:pageList = []
    global/^\d\{3,}$/call add(s:pageList, str2nr(getline('.')))
    let s:pageList = uniq(sort(s:pageList,'n'))
    return s:pageList
    " 监测：输出变量
    " echomsg s:pageList
    " silent! call append('$', s:pageList)
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
    silent! %delete
    let s:fileKeywordsDict = {}
    for i in keys(s:multiFileStd)
        " 加载已经标准化的multiFileStd
        silent! call append('$', s:multiFileStd[i])
        " 清理并保存，以便后续代码可以正常运作
        silent! global/^$/d
        silent! w!
        " 输出每个文件的keywordsDict
        let s:keywordsDict = {}
        silent! vimgrep /^\d\{3,}$/ %
        silent! cdo call KeywordsDict()
        " 合并为multiFile的keywordsDict
        let s:fileKeywordsDict[i] = s:keywordsDict
        silent! %delete
    endfor
    return s:fileKeywordsDict
    " 监测：输出变量
    " echomsg s:fileKeywordsDict
    " silent! call append('$', s:fileKeywordsDict)
    " silent! call append('$', s:fileKeywordsDict[0])
    " for i in keys(s:fileKeywordsDict)
    "     silent! call append('$', s:fileKeywordsDict[i])
    " endfor
endfunction

function! CustomNav(customNavList)
    " 输出自定义导航条
    let customNav = ""
    for customNavKey in a:customNavList
        let customNavKeyword = '<a class="customNavKeyword" href="entry://'
                                \. customNavKey[1] . '">'
                                \. customNavKey[0]
                                \. '</a>'
        let customNav = customNav . customNavKeyword
    endfor
    let customNav = '<div class="customNav">' . customNav . '</div>'
    return customNav
endfunction

function! PagesNav(currentPage, picNamePrefix)
    " 根据所有页码及当前页码所在位置，输出页码导航条
    " 兼容性：页码可以重复、跳页、乱序

    " 定义关键位置和页码
    " 获得当前页码，去除前导符0
    " let currentPage = str2nr(getline('.'))
    let currentPage = a:currentPage

    let cidx = index(s:pageList, currentPage)
    let firstidx = 0
    let lastidx = len(s:pageList) - 1

    let firstPage = s:pageList[0]
    let lastPage = s:pageList[-1]
    let previousPage = get(s:pageList, cidx-1, 'PAGE404')
    let previous2Page = get(s:pageList, cidx-2, 'PAGE404')
    let previous3Page = get(s:pageList, cidx-3, 'PAGE404')
    let nextPage = get(s:pageList, cidx+1, 'PAGE404')
    let next2Page = get(s:pageList, cidx+2, 'PAGE404')
    let next3Page = get(s:pageList, cidx+3, 'PAGE404')

    " 定义链接内容和样式
    let firstPage = PageLink(firstPage, "firstPage", a:picNamePrefix)
    let previous3Page = PageLink(previous3Page, "previous3Page", a:picNamePrefix)
    let previous2Page = PageLink(previous2Page, "previous2Page", a:picNamePrefix)
    let previousPage = PageLink(previousPage, "previousPage", a:picNamePrefix)
    let currentPage = PageLink(currentPage, "currentPage", a:picNamePrefix)
    let nextPage = PageLink(nextPage, "nextPage", a:picNamePrefix)
    let next2Page = PageLink(next2Page, "next2Page", a:picNamePrefix)
    let next3Page = PageLink(next3Page, "next3Page", a:picNamePrefix)
    let lastPage = PageLink(lastPage, "lastPage", a:picNamePrefix)

    " 根据当前页码所在位置，输出相应的pagesNav
    let pagesNav = ""
    if cidx > firstidx
        let pagesNav = firstPage
    endif
    if cidx-4 > firstidx
        let pagesNav = pagesNav . ' ... '
    elseif cidx != firstidx
        let pagesNav = pagesNav . ', '
    endif
    if cidx-3 > firstidx
        let pagesNav = pagesNav . previous3Page . ', '
    endif
    if cidx-2 > firstidx
        let pagesNav = pagesNav . previous2Page . ', '
    endif
    if cidx-1 > firstidx
        let pagesNav = pagesNav . previousPage . ', '
    endif
    let pagesNav = pagesNav . currentPage
    if cidx+1 < lastidx
        let pagesNav = pagesNav . ', ' . nextPage
    endif
    if cidx+2 < lastidx
        let pagesNav = pagesNav . ', ' . next2Page
    endif
    if cidx+3 < lastidx
        let pagesNav = pagesNav . ', ' . next3Page
    endif
    if cidx+4 < lastidx
        let pagesNav = pagesNav . ' ... '
    elseif cidx != lastidx
        let pagesNav = pagesNav . ', '
    endif
    if cidx < lastidx
        let pagesNav = pagesNav . lastPage
    endif
    let pagesNav = '<div class="pagesNav">' . pagesNav . '</div>'
    return pagesNav
endfunction

function! PageLink(page, className, picNamePrefix)
    " 根据页码信息，输出页码对应的链接和样式
    let pageLink = '<a class="pageNum ' . a:className .'" '
            \. 'href="entry://' . a:picNamePrefix
            \. printf(s:pageNumDigit, a:page) . '">'
            \. a:page . '</a>'
    return pageLink
endfunction

function! KeywordsNav(currentPage, currentWord)
    " 输出关键字导航
    let s:multiKeywordsNav = ""
    for file in keys(s:fileKeywordsDict)
        let keywordsNav = ""
        let keywordCount = 0
        let locationPercent = g:multiLevelParts[0][file][2]
        let nearestKeyword = g:multiLevelParts[0][file][3]
        for keyword in get(s:fileKeywordsDict[file], a:currentPage, [])
            if keyword == a:currentWord
                if locationPercent
                    let keyword = '<a class="keywordsNavKeyword currentKeyword" '
                            \. 'href="entry://' . keyword . '">'
                            \. keyword . " "
                            \. printf("%.0f%%", (keywordCount + 1) * 100.0
                            \/len(s:fileKeywordsDict[file][a:currentPage]))
                            \. '</a>'
                else
                    let keyword = '<a class="keywordsNavKeyword currentKeyword" '
                            \. 'href="entry://' . keyword . '">'
                            \. keyword
                            \. '</a>'
                endif
            else
                let keyword = '<a class="keywordsNavKeyword" '
                                \. 'href="entry://' . keyword . '">'
                                \. keyword . '</a>'
            endif
            if keywordCount == 0
                let keywordsNav = keyword
            else
                let keywordsNav = keywordsNav . ", " . keyword
            endif
            let keywordCount = keywordCount + 1
        endfor
        " //////距本页最近的前一个词条
        let currentPage = str2nr(a:currentPage)
        let cidx = index(s:pageList, currentPage)
        let firstPage = s:pageList[0]
        let nearestPrePage = get(s:pageList, cidx-1, s:pageList[-1])
        if nearestPrePage >= firstPage
            while len(get(s:fileKeywordsDict[file], nearestPrePage, [])) == 0
                let nearestPreidx = index(s:pageList, nearestPrePage)
                " 最后一个参数，可实现循环处理
                let nearestPrePage = get(s:pageList, nearestPreidx-1,  s:pageList[-1])
                " 若穷尽页面也没有词条，则输出空
                if nearestPrePage == currentPage
                    break
                endif
            endwhile
            if len(get(s:fileKeywordsDict[file], nearestPrePage, [])) > 0
                let nearestPreKeyword = s:fileKeywordsDict[file][nearestPrePage][-1]
                if nearestKeyword == 0
                    let nearestPreKeyword = ''
                elseif nearestKeyword == 1
                    let nearestPreKeyword = '<a class="nearestKeyword" '
                                    \. 'href="entry://' . nearestPreKeyword . '">'
                                    \. '<<<</a>'
                elseif nearestKeyword == 2
                    let nearestPreKeyword = '<a class="nearestKeyword" '
                                    \. 'href="entry://' . nearestPreKeyword . '">'
                                    \. '(' . nearestPreKeyword. ')<<<</a>'
                endif
            else
                let nearestPreKeyword = ''
            endif
        else
            let nearestPreKeyword = ''
        endif
        " //////距本页最近的后一个词条
        let lastPage = s:pageList[-1]
        let nearestNextPage = get(s:pageList, cidx+1, s:pageList[0])
        if nearestNextPage <= lastPage
            while len(get(s:fileKeywordsDict[file], nearestNextPage, [])) == 0
                let nearestNextidx = index(s:pageList, nearestNextPage)
                " 最后一个参数，可实现循环处理
                let nearestNextPage = get(s:pageList, nearestNextidx+1, s:pageList[0])
                " 若穷尽页面也没有词条，则输出空
                if nearestNextPage == currentPage
                    break
                endif
            endwhile
            if len(get(s:fileKeywordsDict[file], nearestNextPage, [])) > 0
                let nearestNextKeyword = s:fileKeywordsDict[file][nearestNextPage][0]
                if nearestKeyword == 0
                    let nearestNextKeyword = ''
                elseif nearestKeyword == 1
                    let nearestNextKeyword = '<a class="nearestKeyword" '
                                    \. 'href="entry://' . nearestNextKeyword . '">'
                                    \. '>>></a>'
                elseif nearestKeyword == 2
                    let nearestNextKeyword = '<a class="nearestKeyword" '
                                    \. 'href="entry://' . nearestNextKeyword . '">'
                                    \. '>>>(' . nearestNextKeyword. ')</a>'
                endif
            else
                let nearestNextKeyword = ''
            endif
        else
            let nearestNextKeyword = ''
        endif
        " //////拼接导航词条
        let keywordsNav = '<div class="keywordsNav' . file . '">'
                        \. nearestPreKeyword . keywordsNav . nearestNextKeyword
                        \. '</div>'
        let s:multiKeywordsNav = s:multiKeywordsNav . keywordsNav
    endfor
    let s:multiKeywordsNav = '<div class="keywordsNav">'
                            \. s:multiKeywordsNav
                            \. '</div>'
    return s:multiKeywordsNav
endfunction

" 根据sourceStyle和NavStyle输出标准的mdx源文件格式 ---------------------------------{{{1

" 是否所有层级文件的sourceStyle都在指定范围内 -----------------------------{{{2
" 若所有文件的sourceStyle都在列表范围内，则为1，否则为0
function! MultiSourceStyle(sourceStyleList)
    for multiFile in g:multiLevelParts[0]
        let sourceStyle = multiFile[1]
        if index(a:sourceStyleList, sourceStyle) >= 0
            " 若sourceStyle在sourceStyleList列表范围之内，则为1
            let multiSourceStyle = 1
        else
            " 只要有一个未在列表范围内，则为0
            let multiSourceStyle = 0
            break
        endif
    endfor
    return multiSourceStyle
endfunction

if MultiSourceStyle([0,1,2,3]) == 1
    " 运行初始化函数  ---------------------------------------------------{{{2
    " 标准化词条，并存入 s:multiFileStd 字典
    " 创建标准化后的文件字典 s:multiFileStd
    silent! call StandardizeMultiFiles()
    " 创建合并multiFile的PageList
    silent! call PageList()
    " 创建分层级的 s:fileKeywordsDict
    silent! call KeywordsDicts()
    " for i in keys(s:fileKeywordsDict)
    "     silent! call append('$', s:fileKeywordsDict[i])
    " endfor

    " 清空全文
    silent! %delete
    " 将标准化词条转为标准的mdx源文件格式
    if s:navStyle == 0
        " 自身没有页面和keywords导航，仅转LINK
        for currentPage in s:pageList
            for file in keys(s:fileKeywordsDict)
                for currentKeyword in get(s:fileKeywordsDict[file],currentPage,[])
                    silent! let s:navStyleZero = [currentKeyword
                        \, '@@@LINK=' . s:picNamePrefix
                        \. printf(s:pageNumDigit, currentPage)
                        \, '</>']
                    silent! call append('$', s:navStyleZero)
                endfor
            endfor
        endfor
    elseif s:navStyle == 1
        " 仅有页面导航，无keywords导航，简洁
        for currentPage in s:pageList
            silent! let s:navStyleOne = [s:picNamePrefix
                \. printf(s:pageNumDigit, currentPage)
                \, '<link rel="stylesheet" type="text/css" href="' . s:CSSName . '" />'
                \. '<div class="NavTop">'
                \. CustomNav(s:customNavList)
                \. PagesNav(currentPage, s:picNamePrefix)
                \. '</div>'
                \. '<div class="mainbodyimg"><img src="' . s:picNamePrefix
                \. printf(s:pageNumDigit, currentPage)
                \. s:picFormat . '" /></div>'
                \. '<div class="NavBottom">'
                \. PagesNav(currentPage, s:picNamePrefix)
                \. "</div>"
                \, '</>']
            silent! call append('$', s:navStyleOne)
            for file in keys(s:fileKeywordsDict)
                for currentKeyword in get(s:fileKeywordsDict[file],currentPage,[])
                    silent! let s:navStyleZero = [currentKeyword
                        \, '@@@LINK=' . s:picNamePrefix
                        \. printf(s:pageNumDigit, currentPage)
                        \, '</>']
                    silent! call append('$', s:navStyleZero)
                endfor
            endfor
        endfor
    elseif s:navStyle == 2
        " 不仅有页面导航，而且有keywords导航
        for currentPage in s:pageList
            silent! let s:navStyleTwo = [s:picNamePrefix
                \. printf(s:pageNumDigit, currentPage)
                \, '<link rel="stylesheet" type="text/css" href="' . s:CSSName . '" />'
                \. '<div class="NavTop">'
                \. CustomNav(s:customNavList)
                \. PagesNav(currentPage, s:picNamePrefix)
                \. KeywordsNav(currentPage, "")
                \. '</div>'
                \. '<div class="mainbodyimg"><img src="' . s:picNamePrefix
                \. printf(s:pageNumDigit, currentPage)
                \. s:picFormat . '" /></div>'
                \. '<div class="NavBottom">'
                \. PagesNav(currentPage, s:picNamePrefix)
                \. "</div>"
                \, '</>']
            silent! call append('$', s:navStyleTwo)
            for file in keys(s:fileKeywordsDict)
                for currentKeyword in get(s:fileKeywordsDict[file],currentPage,[])
                    silent! let s:navStyleOne = [currentKeyword
                        \, '<link rel="stylesheet" type="text/css" href="' . s:CSSName . '" />'
                        \. '<div class="NavTop">'
                        \. CustomNav(s:customNavList)
                        \. PagesNav(currentPage, s:picNamePrefix)
                        \. KeywordsNav(currentPage, currentKeyword)
                        \. '</div>'
                        \. '<div class="mainbodyimg"><img src="' . s:picNamePrefix
                        \. printf(s:pageNumDigit, currentPage)
                        \. s:picFormat . '" /></div>'
                        \. '<div class="NavBottom">'
                        \. PagesNav(currentPage, s:picNamePrefix)
                        \. "</div>"
                        \, '</>']
                    silent! call append('$', s:navStyleOne)
                endfor
            endfor
        endfor
    else
        echomsg "请定义 NavStyle " . s:NavStyle . " 的处理方案"
    endif
else
    echomsg "请定义 SourceStyle " . s:sourceStyle . " 的处理方案"
endif

" 将输出结果保存到mdxSource  ----------------------------------------------{{{1
silent! global/^$/d
let g:mdxSource = extend(g:mdxSource, getline(1, "$"))

" Reference  --------------------------------------------------------------{{{1
finish

" 在新Tab页打开output文件
silent! tabe %:r.output.%:e

/* vim: set et sw=4 ts=4 sts=4 fdm=marker ff=unix ft=vim fenc=utf8 nobomb: */
