import { marked } from "marked";
import GithubSlugger from 'github-slugger';

const regex = /^\[\^([^\]]+)\](?!:)/;
// https://en.wikipedia.org/wiki/Dingbat for future inspiration
const marginMarks = ["⁜", "†", "‡"];
let marginMarksIndex = 0;

const slugger = new GithubSlugger();

export const marginnote = {
  name: "marginnote",
  level: "inline",
  start(src) {
    return src.match(regex)?.index || -1;
  },
  tokenizer(src, tokens) {
    const match = regex.exec(src);
    if (match) {
      const raw = match[0];
      const body = match[1];
      const [kind, note] = body.split(":");
      const slug = slugger.slug(kind);
      const token = {
        type: "marginnote",
        raw,
        kind,
        note,
        slug,
      };
      return token;
    }
  },
  renderer(token) {
    const sidenote = token.kind !== "aside" ? true : false;
    const marginMark = !sidenote ? marginMarks[marginMarksIndex] : "";
    marginMarksIndex = marginMark
      ? marginMarksIndex + 1 === marginMarks.length
        ? 0
        : marginMarksIndex + 1
      : marginMarksIndex;
    return `
   <label class="margin-toggle ${sidenote ? "sidenote-number" : "marginnote-symbol"}" for="${
      token.slug
    }"><a href="#${token.slug}-ref" aria-text="jump to margin note">${marginMark}</a>
   </label> 
   <input class="margin-toggle" id="${token.slug}" type="checkbox">
   <span id="${token.slug}-ref" class="${sidenote ? "sidenote" : "marginnote"}" data-symbol="${marginMark}">${token.note}</span>
    `;
  },
};
