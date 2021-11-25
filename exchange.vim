silent! set expandtab tabstop=4 | %retab
" 将格式转为sourceStyle 2
silent! %s/^\(.\{-}\)\s\{4,}\(\d\{3,}\)$/\2    \1/
normal gg
let linenumber = printf('%04d', 0)
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
