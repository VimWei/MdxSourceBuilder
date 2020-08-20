" 读取词典参数 ------------------------------------------------------------{{{1

let s:CSSName = g:CSSName
let s:customNavList = g:customNavList
let s:picNamePrefix = dictionaryPart[1]
let s:picFormat = dictionaryPart[2]
let s:PageKeywordStyle = dictionaryPart[3]
let s:KeywordsNavStyle = dictionaryPart[4]

" mdx源文件格式初始化 -----------------------------------------------------{{{1
" 清理并保存，以便后续代码可以正常运作
silent! normal! Go
silent! global/^$/d
silent! w!

" 将input词条格式标准化 ---------------------------------------------------{{{1
if s:PageKeywordStyle == 0
    " 适合如下标准词条格式：一行页码 + 多行关键词（每行一个关键词）
    " 0001
    " a
    " b
    " c
    " 0002
    " x
    " y
    " z
elseif s:PageKeywordStyle == 1
    " 适合如下词条格式：行格式为'一个页码+多个中文单字符的关键词'
    " 0001吖阿啊锕腌啊嗄啊哎
    " 0002哀埃挨唉锿挨皑癌毐欸嗳矮蔼
    " 0003霭艾砹唉爱隘碍嗳嗌媛瑷

    " 以下将的单行格式转换为标准词条格式
    " 将页码换行
    silent! %s/^\d\{4}\($\)\@!/\0\r/e
    " 将每个字独立成行
    silent! %s/\D\($\)\@!/\0\r/ge
    " 清理并保存，以便后续代码可以正常运作
    silent! normal! Go
    silent! global/^$/d
    silent! w!
elseif s:PageKeywordStyle == 2
    " 适合如下词条格式：行格式为"页码 + 分隔符 + 单个中或英关键词"
    " 分隔符兼容：Tab键'\t', 4个及以上空格'\s\{4,}'
    " 0001    abandon
    " 0001    abandoned
    " 0002    abandonee
    " 0002    a bas
    " 0003    abdominous

    normal gg
    silent! %s/\t/    /e
    let linenumber = "0000"
    for line in getline(1,'$')
        let words = split(line, '\s\{4,}')
        if linenumber == words[0]
            silent! s/^.*$/\= words[1]/e
        else
            let linenumber = words[0]
            silent! s/^.*$/\= words[0] . "\n". words[1]/e
        endif
        silent! normal j
    endfor
    " 清理并保存，以便后续代码可以正常运作
    silent! normal! Go
    silent! global/^$/d
    silent! w!
endif

" 创建pageList 和 keywordsDict --------------------------------------------{{{1

" 创建、排序、去重 pageList
let s:pageList = []
global/^\d\{4}$/call add(s:pageList, str2nr(getline('.')))
let s:pageList = uniq(sort(s:pageList,'n'))
" echomsg s:pageList

" 创建 keywordsDict
let s:keywordsDict = {}
silent! vimgrep /\d\d\d\d$/ %
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
silent! cdo call KeywordsDict()
" echomsg s:keywordsDict

" 清空全文
silent! normal! ggdG

" CustomNav() 输出自定义导航条 --------------------------------------------{{{1
function! CustomNav(customNavList)
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

" PagesNav() 输出页码导航条 -----------------------------------------------{{{1
function! PagesNav(currentPage, picNamePrefix)
    " 根据所有页码及当前页码所在位置，输出相应的pagesNav
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
    let nextPage = get(s:pageList, cidx+1, 'PAGE404')
    let next2Page = get(s:pageList, cidx+2, 'PAGE404')

    " 定义链接内容和样式
    let firstPage = PageLink(firstPage, "firstPage", a:picNamePrefix)
    let previous2Page = PageLink(previous2Page, "previous2Page", a:picNamePrefix)
    let previousPage = PageLink(previousPage, "previousPage", a:picNamePrefix)
    let currentPage = PageLink(currentPage, "currentPage", a:picNamePrefix)
    let nextPage = PageLink(nextPage, "nextPage", a:picNamePrefix)
    let next2Page = PageLink(next2Page, "next2Page", a:picNamePrefix)
    let lastPage = PageLink(lastPage, "lastPage", a:picNamePrefix)

    " 根据当前页码所在位置，输出相应的pagesNav
    let pagesNav = ""
    if cidx > firstidx
        let pagesNav = firstPage
    endif
    if cidx-3 > firstidx
        let pagesNav = pagesNav . ' ... '
    elseif cidx != firstidx
        let pagesNav = pagesNav . ', '
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
            \. printf("%04d", a:page) . '">'
            \. a:page . '</a>'
    return pageLink
endfunction

" KeywordsNav() 输出页面关键字导航条 --------------------------------------{{{1
function! KeywordsNav(currentPage, currentWord)
    " 输出关键字导航
    let keywordsNav = ""
    let keywordCount = 0
    for keyword in s:keywordsDict[a:currentPage]
        if keyword == a:currentWord
            let keyword = '<a class="keywordsNavKeyword currentKeyword" '
                    \. 'href="entry://' . keyword . '">'
                    \. keyword . " "
                    \. printf("%.0f%%", (keywordCount + 1) * 100.0/len(s:keywordsDict[a:currentPage]))
                    \. '</a>'
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
    let keywordsNav = '<div class="keywordsNav">' . keywordsNav . '</div>'
    return keywordsNav
endfunction

" 将标准化input词条转为页面导航源文件格式 ---------------------------------{{{1
if s:KeywordsNavStyle == 0
    " 自身没有页面和keywords导航，仅转LINK
    for currentPage in s:pageList
        for currentKeyword in s:keywordsDict[currentPage]
            silent! let @k = currentKeyword . "\n"
                \. '@@@LINK=' . s:picNamePrefix . printf("%04d", currentPage) . "\n"
                \. '</>'
            silent! $put k
        endfor
    endfor
elseif s:KeywordsNavStyle == 1
    " 仅有页面导航，无keywords导航，简洁
    for currentPage in s:pageList
        silent! let @p = s:picNamePrefix . printf("%04d", currentPage) . "\n"
            \. '<link rel="stylesheet" type="text/css" href="' . s:CSSName . '" />'
            \. '<div class="NavTop">'
            \. PagesNav(currentPage, s:picNamePrefix)
            \. CustomNav(s:customNavList)
            \. '</div>'
            \. '<div class="mainbodyimg"><img src="' . s:picNamePrefix
            \. printf("%04d", currentPage) . s:picFormat . '" /></div>'
            \. '<div class="NavBottom">'
            \. PagesNav(currentPage, s:picNamePrefix)
            \. "</div>\n"
            \. '</>'
        silent! $put p
        for currentKeyword in s:keywordsDict[currentPage]
            silent! let @k = currentKeyword . "\n"
                \. '@@@LINK=' . s:picNamePrefix . printf("%04d", currentPage) . "\n"
                \. '</>'
            silent! $put k
        endfor
    endfor
elseif s:KeywordsNavStyle == 2
    " 不仅有页面导航，而且有keywords导航
    for currentPage in s:pageList
        silent! let @p = s:picNamePrefix . printf("%04d", currentPage) . "\n"
            \. '<link rel="stylesheet" type="text/css" href="' . s:CSSName . '" />'
            \. '<div class="NavTop">'
            \. PagesNav(currentPage, s:picNamePrefix)
            \. KeywordsNav(currentPage, "")
            \. '</div>'
            \. '<div class="mainbodyimg"><img src="' . s:picNamePrefix
            \. printf("%04d", currentPage) . s:picFormat . '" /></div>'
            \. '<div class="NavBottom">'
            \. CustomNav(s:customNavList)
            \. PagesNav(currentPage, s:picNamePrefix)
            \. "</div>\n"
            \. '</>'
        silent! $put p
        for currentKeyword in s:keywordsDict[currentPage]
            silent! let @k = currentKeyword . "\n"
                \. '<link rel="stylesheet" type="text/css" href="' . s:CSSName . '" />'
                \. '<div class="NavTop">'
                \. PagesNav(currentPage, s:picNamePrefix)
                \. KeywordsNav(currentPage, currentKeyword)
                \. '</div>'
                \. '<div class="mainbodyimg"><img src="' . s:picNamePrefix
                \. printf("%04d", currentPage) . s:picFormat . '" /></div>'
                \. '<div class="NavBottom">'
                \. CustomNav(s:customNavList)
                \. PagesNav(currentPage, s:picNamePrefix)
                \. "</div>\n"
                \. '</>'
            silent! $put k
        endfor
    endfor
endif

" 将输出结果保存到mdxSource  ----------------------------------------------{{{1
silent! global/^$/d
silent! normal! gg"xyG
let g:mdxSource = g:mdxSource . @x

" Reference  --------------------------------------------------------------{{{1
finish

" 在新Tab页打开output文件
silent! tabe %:r.output.%:e
