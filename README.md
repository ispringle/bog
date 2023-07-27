# Bog

## The static site generator of despond

>> "This miry slough is such a place as cannot be mended; it is the hollow
>> whither the scum and filth that go with the feeling of sin, do continually
>> run, and therefore it is called the Slough of Despond; for still, as the
>> sinner is awakened by his lost condition, there arise in his soul many
>> fears, and doubts, and discouraging alarms, which all of them get together
>> and settle in this place; and this is the reason of the badness of the
>> ground.
>>
>> "It is not the pleasure of the King that this place should remain so bad.
>> His laborers also have, by the direction of His Majesty's surveyors, been
>> for about these sixteen hundred years employed about this patch of ground,
>> if perhaps it might have been mended [...]"
>> John Bunyan's <cite>[The Pilgrim's Progress](
>> "https://www.gutenberg.org/files/39452/39452-h/39452-h.htm#Page_22")</cite>,
>> Page 22

## A Brief History of Despair

Websites are thrilling and addicting to create. Keeping up with them and being stasified with what you end up with is not so easy. Bog isn't a solution to this problem, but the name "Bog" is a response to this reality. In the past I've created websites with various tools including Jekyl, Hugo, NextJS, Zola, AstroJS, SvelteKit, plain HTML files, Wordpress, and a few others. Each site was good but not good enough and ultimately was relegated to the dustbin of GitHub or just deleted entirely.

Throughout these trials, I've continued to come back to a few key values regarding personal websites:

1. A personal website is first and foremost a product for the owner of it
2. A personal website's aesthetic ought please the owner but it ought to be functional for anyone else
3. A personal website ought not conform to modern SEO UX design standards, unless the owner wishes this to be so

Additionally, I have some thoughts about _my_ website in particular and how it's created and how it displays content:

1. My website ought display prose and verse beautifully and without undue distractions
2. My website ought to be joyful
3. My website needs to be simple to maintain and deploy

To these ends, and others, I have decided to create Bog. Bog is the next iteration of my web creation tooling. Previous to Bog I used Sylvan, which is a site generator that has gone back and forth between using NextJS and AstroJS as a framework, and has gone back and forth between rendering Orgmode files and Obsidian's flavor of Markdown. Sylvan had grand goals of being useable by anyone. Bog has no such goal. Bog is _my_ tool. You are free to look at Bog, use Bog, or modify Bog, but Bog is _my_ tool and it will never be extended (by me) to cater to others, whether that "other" is a real or figurative person.

## Todo

- [X] Basic .md syntax
- [ ] Markdown modifications
  - [ ] "Slack style" italics and bold (_italics_, *bold*)
- [ ] Tufte-CSS Syntax HTML
  - [X] Epigraphs with optional footers
  - [X] Citations
  - [X] Document Title convention
  - [X] Document Subtitle convention
  - [ ] Sidenotes
  - [ ] Margin notes
  - [ ] Figure convention
  - [ ] Margin figures
  - [ ] Fullwidth figures
  - [ ] "Sectionize" articles
- [X] Tufte compliant TOC Generation
- [ ] Better <code> handling and highlighting with Bright
- [ ] Two-way Backlinks
- [ ] Index page generation
- [ ] Metadata extraction/generation (frontmatter+implicit metadata => microformats)
- [ ] Hover to preview
- [X] Drop-cap :first-letter