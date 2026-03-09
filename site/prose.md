---
title: Prose Test
description: A rich markdown page testing all supported elements
canonical: https://example.com/prose
---
# Prose Test

A rich markdown page exercising all elements that 3bmd supports. Check source for `<link rel=canonical>`.

## Inline elements

A paragraph with **bold**, *italic*, ~~strikethrough~~, `inline code`, and a [link to home](/).

Text with a hard  
line break (two trailing spaces).

## Blockquote

> The art of programming is the art of organizing complexity.
>
> — Dijkstra

## Code blocks

Lisp:

```lisp
(defun fib (n)
  (if (< n 2) n
      (+ (fib (- n 1))
         (fib (- n 2)))))
```

JavaScript:

```javascript
const fib = n => n < 2 ? n : fib(n - 1) + fib(n - 2);
```

No language tag:

```
plain preformatted text
  preserved indentation
```

## Lists

Unordered:

- Alpha
- Beta
  - Nested item
  - Another nested
- Gamma

Ordered:

1. First
2. Second
3. Third

## Horizontal rule

---

## Heading levels

All headings below are in source as h2–h5. After `normalize-headings` they should render as h3–h6.

### h3 in source → h4

#### h4 in source → h5

##### h5 in source → h6

## What to verify

- View source: `<link rel="canonical" href="https://example.com/prose">` in `<head>`
- View source: `<meta name="description">` is set
- Title is "Prose Test"
- Heading levels are shifted down by one

[← Home](/)
