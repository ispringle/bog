#!/bin/bash
file=$1
cmark="cmark --smart --unsafe --to xml"

xml="$(${cmark} ${file})"

xml_stylesheet="scripts/tufte.xsl"
xsltproc="xsltproc --novalid --nonet ${xml_stylesheet}"

html="$(echo ${xml} | ${xsltproc} -)"
echo $html