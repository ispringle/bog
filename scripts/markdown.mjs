#!/usr/bin/env node
import { marked } from 'marked'
import { mangle } from 'marked-mangle'

import { gfmHeadingId } from 'marked-gfm-heading-id'
import { markedSmartypants } from "marked-smartypants";

import {extensions, hooks, renderer, globalSlugger} from './marked-ext/index.mjs'

marked.use({ headerIds: false, gfm: true, hooks, extensions, renderer, slugger: globalSlugger }, mangle(), markedSmartypants())

import 'marked/bin/marked'
