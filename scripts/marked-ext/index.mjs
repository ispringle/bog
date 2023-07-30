import admonition from './admonitions.mjs'
import citation from './citation.mjs'
import epigraph from './epigraph.mjs'
import footer from './footer.mjs'
import sections from './sections.mjs'

import { headingRenderer } from './headings.mjs'
import { marginnote} from './marginnote.mjs'

import GithubSlugger from 'github-slugger';

const globalSlugger = new GithubSlugger();;
const hooks = {
      preprocess(src) {
        let slugger = globalSlugger
        return src;
      }
}

const extensions = [citation, epigraph, footer, marginnote, sections]
const renderer = {heading: headingRenderer}
const tokenizer = {}

export { extensions, hooks, renderer, tokenizer, globalSlugger}
