---
title: Second Post
description: Another subdirectory routing test
---
# Second Post

This page lives at `pages/blog/second-post.md`.

Verifies that multiple pages in the same subdirectory all resolve correctly and don't interfere with each other's cache entries.

## Cache isolation

Each page is cached by its full file path as key. `/blog/first-post` and `/blog/second-post` are independent cache entries. Touching one file should not invalidate the other.

[← First Post](/blog/first-post) · [← Blog](/blog) · [← Home](/)
