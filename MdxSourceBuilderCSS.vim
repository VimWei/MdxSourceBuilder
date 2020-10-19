/* 顶部的导航 */
.NavTop {
    margin: 0 0 10px 0;
    text-align: center;
}

/* 顶部的页面导航 */
.NavTop .pagesNav {
    background-color: #CC9933;
    color: #FFFF99;
}
.NavTop .pageNum {
    color: #FFFF99;
    padding: 0 5px;
    text-decoration: none;
}
.firstPage {}
.previousPage {
    font-size:130%;
}
.previous2Page {
    font-size:110%;
}
.currentPage {
    font-size: 150%;
    font-weight: 600;
    color: red!important;
}
.nextPage {
    font-size:130%;
}
.next2Page {
    font-size:110%;
}
.lastPage {}

/* 关键词导航 */
.keywordsNav {
    color: blue;
}
.keywordsNavKeyword {
    padding: 0 5px;
    text-decoration: none;
}
.currentKeyword {
    color: red;
    font-weight: 700;
}
.subkeywords .keywordsNavKeyword {
    padding: 0;
}

/* 正文图片 */
.mainbodyimg img {
    /* 设置图片大小 */
    width: 100%;
    /* width: 42em; */
    /* display: block; */
    /* margin-left: auto; */
    /* margin-right: auto; */

    /* 对于透明图片的词典，可更改背景色以适应黑夜模式 */
    /* 取消以下background-color的注释，并挑选您喜欢的颜色 https://encycolorpedia.cn/named */
    /* background-color: linen; */
}

/* 底部的导航 */
.NavBottom {
    margin: 10px 0 0 0;
    text-align: center;
}

/* 自定义导航 */
.customNav {}
.customNavKeyword {
    padding: 0 5px;
    text-decoration: none;
}

/* 底部的页面导航 */
.NavBottom .pagesNav {
    background-color: #EAEAEA;
    color: black;
}
.NavBottom .pageNum {
    color: black;
    padding: 0 5px;
    text-decoration: none;
}
.NavBottom .currentPage {
    font-size: 150%;
    font-weight: 600;
    color: red!important;
}

/* vim: set et sw=4 ts=4 sts=4 fdm=marker ff=unix ft=css fenc=utf8 nobomb: */
