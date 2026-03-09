---
title: Bog Test Site
description: Visual test suite for the bog web framework
---
# Bog Test Site

A test suite for visually verifying bog's rendering pipeline. Each page tests a different feature.

## Pages

- [/about](/about) - `.lisp` static page: `defpage`, `with-page`, heading normalization
- [/mutable](/mutable) - `.lisp` mutable: `defpage :mutable t`, dynamic content
- [/colophon](/colophon) - `.html` fragment: `<head>` hoisting, title extraction
- [/standalone](/standalone) - `.html` full doc: passthrough, no layout wrapping
- [/prose](/prose) - `.md` rich: all markdown elements, canonical URL
- [/blog](/blog) - `.lisp` mutable index: auto-lists posts
- [/missing](/missing) - 404 handler
- [/source](/source) - The bog source files.

## Front Matter

This page has `title` and `description` set via front matter. View source to verify `<title>` and `<meta name="description">`.

## Heading Normalization

The `normalize-headings` postprocess shifts all headings down one level so the layout `<h1>` (site name) is the only h1 on the page. The `# Bog Test Site` above is h1 in source but should render as h2.

### This h3 in source should render as h4
