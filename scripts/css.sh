#!/bin/bash
minify="$(npm bin)/minify"
normalize="$(npm root)/normalize.css/normalize.css"
style="styles/main.css"
tufte_dir="$(npm root)/tufte-css"
tufte_css="${tufte_dir}/tufte.css"
et_book_dir="${tufte_dir}/et-book/"

cp -r $et_book_dir site/styles/et-book/
cat ${tufte_css} | ${minify} --css > site/styles/tufte.min.css
cat ${normalize} | ${minify} --css > temp/normalize.min.css
cat ${style} | ${minify} --css > site/styles/main.min.css