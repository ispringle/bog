# Lorem Ipsum

## Ian S. Pringle

## A brief introduction

[Bog](https://github.com/ispringle/bog) is a tool for creating my
[website](https://drollery.org/) from Markdown files and some HTML. It turns the
`.md` files into HTML that is compliant (mostly, minus my modifications) with
tufte-css. In order to accamodate some features of of the tufte-css stylesheet,
the Markdown syntax had to be added to and modified. Additionally, I dislike
some things about Markdown and so I've modified it to meet my own needs and
desires. This document enumerates the syntax of Bog, its conventions, and acts
of a visual test bed to verify the syntax and features of Bog are working.

[Markdown](https://daringfireball.net/projects/markdown/) is a plain text format
for writing structured documents, based on formatting conventions from email and
usenet.  It was developed in 2004 by John Gruber.

[tufte-css](https://edwardtufte.github.io/tufte-css/) provides tools to style
web articles using the ideas demonstrated by Edward Tufte's books and handouts.
It was created by [Dave Liepmann](http://www.daveliepmann.com/) in late 2015 and
is now an Edward Tufte project.

Bog has two main goals:

### I: Generate tufte-css compliant web pages from Markdown

The first goal of Bog is to generate tufte-css styled web pages from plain text
files that follow the CommonMark specification.

### II: Generate a website that is beautiful and joyful

The second goal of Bog is to generate a static website that is a joy to interact
with and provides optional features that will not get in the way of browsing and
can be entirely turned off (for example via noscript) without ruining the
website's core functionalit.

## Markdown Syntax

### The Basics

### Bog-specific syntax

To support Tufte-CSS, there are a number of additional elements to a markdown
file including citations, epigraphs with optional "footer", and I fixed a few
grievances I have with markdown along the way.

### Citations

The HTML5 standard provides a `<cite>` element which signifies that the thing it contains is a citation. This is pretty handy to have access to I think, but there is no means of specifying a citation with Markdown. Because of this I have come up with a special citation syntax which consists of two dashes wrapping text. There is to be *no* spaces separating the dashes from text, otherwise the two dashes will be treated as an emdash ( -- ) instead:

```
--[Lorem Ipsum](https://www.lipsum.com/)-- has been the industry standard in dummy-text since the 1500s!
```

--[Lorem Ipsum](https://www.lipsum.com/)-- has been the industry standard in dummy-text since the 1500s!

### Epigraphs

Tufte made ample use of
[epigraphs](https://en.wikipedia.org/wiki/Epigraph_(literature)) in his writings
and the tufte-css stylesheet has a means of rendering them. To do so in Bog's
modified markdown syntax we use two `>`. This is similar to how a blockquote is
expressed in standard markdown.

```markdown
>> Laborum Lorem dolore minim deserunt dolor ullamco qui minim consequat in
>> labore. _Pariatur deserunt_ et nostrud elit laboris voluptate. Aliquip
>> excepteur fugiat ullamco *veniam veniam* aliqua cillum labore anim consectetur
>> esse ullamco fugiat dolore.
```

>> Laborum Lorem dolore minim deserunt dolor ullamco qui minim consequat in
>> labore. _Pariatur deserunt_ et nostrud elit laboris voluptate. Aliquip
>> excepteur fugiat ullamco *veniam veniam* aliqua cillum labore anim consectetur
>> esse ullamco fugiat dolore.

A Tufte-style epigraph can also have a "footer" which is essentially a citation. To express that the line is the footer of the epigraph use three `>`:

```markdown
>> Laborum Lorem dolore minim deserunt dolor ullamco qui minim consequat in
>> labore. _Pariatur deserunt_ et nostrud elit laboris voluptate. Aliquip
>> excepteur fugiat ullamco *veniam veniam* aliqua cillum labore anim consectetur
>> esse ullamco fugiat dolore.
>>> -- Ullamco Sunt's --Incididunt Esse Sit--, 1023
```

>> Laborum Lorem dolore minim deserunt dolor ullamco qui minim consequat in
>> labore. _Pariatur deserunt_ et nostrud elit laboris voluptate. Aliquip
>> excepteur fugiat ullamco *veniam veniam* aliqua cillum labore anim consectetur
>> esse ullamco fugiat dolore.
>>> -- Ullamco Sunt's --Incididunt Esse Sit--, 1023

### Side Notes & Margin Notes

Tufte-CSS has a style of footnote it calls a "side note"[^fn:This is a footnote
which appears in the margin rather than at the bottom of the document].  Like a
side note, there is also a "margin note"[^aside:A margin note represents some aside
that is only accilary to the discourse] which is a note without a reference
number.  On narrow screens where the margin is not wide enough or is not present
these notes instead can be toggled and will appear below the reference.

A note[^aside:By "note" I mean both side notes and margin notes] has the format of:

```markdown
[^kind:note content]
```

The "kind" for the note determines two things; whether a note is a side note or a margin note and the id used for the note. By convention a side note uses the kind "fn"[^note:However any "kind" other than "aside" can be used to mark a side note, this way side notes can have unique URLs.]. A margin note *must* have the kind "aside"[^aside:The GithubSlugger package ensures that all id's are unique even if they are the same word.].

Like footnotes, a side note uses a number to match the note to the place it's
referenced[^aside:The way that tufte-css works, these numbers are actually computed with CSS!]. Margin notes do not use numbers but instead use a list of symbols.
Once all the symbols have been used up they'll loop back to the first symbol
again[^aside:The symbols that are used are "⁜", "†", and "‡"].

### Figure convention

CommonMark supports images by using the construction:

```markdown
![alt](url "title")]
```

that gets translated by CommonMark into the following HTML:

```html
<img src='url' alt='alt' title='title' />
```

Sadly nor CommonMark nor Markdown support figures with captions [(there's an ongoing discussion, though)](http://talk.commonmark.org/t/image-tag-should-expand-to-figure-when-used-with-title/265/5). 

To overcome this limitation xmark uses the following convention

> Use the 'alt' text as the caption for the figure, and abuse the 'title' text as both the HTML alt and the title.

So, for instance, the following text:

``` markdown
![From Edward Tufte, *Visual Display of 
Quantitative Information*, 
page 92.](tufte-css/img/exports-imports.png 
"Visual Display of Quantitative Information")
```

Will be transformed in the following ```<figure>```, ```<img>``` and ```<caption>```:

![From Edward Tufte, *Visual Display of Quantitative Information*, page 92.](https://raw.githubusercontent.com/edwardtufte/tufte-css/a2953c038d86dae89aad9ced814bc685cee0ae91/img/exports-imports.png "Visual Display of Quantitative Information")

Note that figures are automatically numbered by xmark.

### Margin and full-width figure conventions

Graphics that are ancillary to the main body of the text are placed in margin figures in tufte-css. 

But CommonMark and Markdown have just a single construct for images.  ![F.J. Cole, “The History of Albrecht Dürer’s Rhinoceros in Zooological Literature,” *Science, Medicine, and History: Essays on the Evolution of Scientific Thought and Medical Practice (London, 1953)*, ed. E. Ashworth Underwood, 337-356. From page 71 of Edward Tufte’s *Visual Explanations*.](https://raw.githubusercontent.com/edwardtufte/tufte-css/a2953c038d86dae89aad9ced814bc685cee0ae91/img/rhino.png "margin Rhino image") 

How could xmark support margin figures easily? By abusing the construct, of course. 

xmark abuses the title part of the image (that appears when you place the mouse over the image for a while), and if the title starts with the word 'margin' then the image is placed in a margin note, and if the title starts with the word 'fullwidth' then the image will be rendered as a full-width figure. The conventions are then:

> If the title of the image starts with the word ```margin``` the figure will be placed in the margin.

> If the title of the image starts with the word ```fullwidth``` the figure will be full-width.

So any image constructed like this:

```markdown
![text caption here](image-name-or-url "margin Rhino image")
```

(note the ```margin``` word at the beginning of the title) will be considered a margin figure.

And the following markup:
    
```markdown
![Edward Tufte’s English translation of the 
Napoleon’s March data visualization. 
From *Beautiful Evidence*, page
122-124.](tufte-css/img/napoleons-march.png 
"fullwidth Napoleon's march").
```

Will be rendered as:

![Edward Tufte’s English translation of the Napoleon’s March data visualization. From *Beautiful Evidence*, page 122-124.](https://raw.githubusercontent.com/edwardtufte/tufte-css/a2953c038d86dae89aad9ced814bc685cee0ae91/img/napoleons-march.png "fullwidth Napoleon's march").

Note that the ```margin``` and ```fullwidth``` special words are removed from the resulting HTML figure title. As in Tufte-CSS, full-width images are also numbered automaticcally with xmark.

### Source code convention

Source code is translated to tufte-css equivalents, but CommonMark's ```info-string``` tag is kept, so it is possible to remember which programming language is being used for each part of the code.

So, for instance, the markdown paragraph:

```` markdown
``` ruby
def foo(x)
        return 3
end
```
````

That is tagged as a Ruby program, will be translated to the HTML equivalent:

``` html
<pre class='code'><code class='language-ruby code'>def foo(x)
        return 3
end</code></pre>
```

## Deviations from tufte-css

### Table of Contents

xmark automatically generates a Table of Contents and places it in a marginnote at the top of the document.

You can disable this feature by setting the XSLT parameter ```generate-toc``` to ```no``` (see below for an example).

### Sections

xmark does not generate ```<section>``` HTML 5 tags.

### Syntax highlighting

xmark automatically embeds some ```<script>``` and CSS stylesheets from [highlight.js](https://github.com/isagalaev/highlight.js) to enable language-specific syntax highlighting.

You can disable this feature by setting the XSLT parameter ```highlight``` to ```no```.

## Using xmark

In order to use xmark one needs the following software:

1. A CommonMark processor that generates XML, such as the excellent [John MacFarlane's cmark](https://github.com/jgm/cmark).
2. The tufte-css project under the 'tufte-css' folder in a working directory of your liking.
3. The xmark.xsl stylesheet, [available here](https://github.com/vieiro/xmark/blob/master/xmark.xsl).
4. An XSLT processor, such as [xsltproc](http://www.xmlsoft.org). If you're using Mac OS/X, Linux or FreeBSD you may already have it installed.

If you have cloned [xmark's github repository](https://github.com/vieiro/xmark) you can issue the ```git submodule init``` command to clone CommonMark's cmark and tufte-css projects.

Once everything is set up you process your CommonMark file (```myfile.markdown```) with cmark, and then pipe that to xsltproc to generate an output file ```myfile.html```, like so:

    cmark -t xml myfile.markdown | xsltproc --novalid --nonet xmark.xsl - > myfile.html

Or, if you want to disable the Table of Contents:

    cmark -t xml myfile.markdown | xsltproc --novalid --nonet \
       --stringparam generate.toc no xmark.xsl - > myfile.html

And, if you want to disable syntax highlighting:

    cmark -t xml myfile.markdown | xsltproc --novalid --nonet \
       --stringparam highlight no xmark.xsl - > myfile.html

### License

xmark is released under the MIT License.

## Further reading

Some links you may find of interest:

* [Tufte CSS homepage](https://edwardtufte.github.io/tufte-css/)
* [CommonMark homepage](http://commonmark.org)
* [xmark's project page at github](https://github.com/vieiro/xmark).
* [The source of this document](https://raw.githubusercontent.com/vieiro/xmark/master/test.markdown)
* [This document as rendered by GitHub](https://github.com/vieiro/xmark/blob/master/test.markdown)

## Epilogue

Many thanks go to Edward Tufte, Dave Liepmann, John Gruber, John MacFarlane, Ivan Sagalaev and the CommonMark volunteers.


