let sectionLevel = 0;
let hgroupSet = false;
let subtitleRendered = false;

const sectionRegexps = new Array(7).fill().map((e, i) => new RegExp(`^(#{${i + 1}} )[^]*?(?:\\n(?=\\1)|$)`));
const hgroupRegex = /^(#{1}[ ]?[^]*?[\n$]+?#{2}[ ]?[^]*?\n)([^]*?(?:\\n(?=\\1)|$))/

const extension = {
    name: 'section',
    level: 'block',
    start(src) {
        return src.match(/^#/m)?.index;
    },
    tokenizer(src) {
        const match = src.match(sectionRegexps[sectionLevel]);
        if (match) {
            sectionLevel++;
            let tokens;
            const hgroup = {};
            let kind = "heading"
            if (!hgroupSet && src.match(hgroupRegex)) {
                const hgroupMatch = src.match(hgroupRegex)
                hgroup.tokens = this.lexer.blockTokens(hgroupMatch[1]),
                tokens = this.lexer.blockTokens(hgroupMatch[2]);
                hgroupSet = true;
                kind = "hgroup"
            } else {
                tokens = this.lexer.blockTokens(match[0]);
            }
            sectionLevel--;
            const header = match[0].split("\n")[0].replaceAll("#", "")
            return {
                type: 'section',
                raw: match[0],
                header,
                kind,
                level: sectionLevel + 1,
                hgroup,
                tokens
            };
        }
    },
    renderer(token) {
        const id = this.parser.slugger.slug(`section${token.header}`);
        if (token.level === 1 && token.kind === "hgroup") {
            return `<article id="content"><hgroup>${this.parser.parse(token.hgroup.tokens)}</hgroup>${this.parser.parse(token.tokens)}</article>`
        } else if (token.level === 1) {
            return `<article id="content"><hgroup>${this.parser.parse(token.tokens[0])}</hgroup>${this.parser.parse(token.tokens)}</article>`
        } else if (hgroupSet && token.level === 2 && !subtitleRendered) {
            subtitleRendered = true;
            return `${this.parser.parse(token.tokens)}`
        } else {
            return `<section id="${id}">\n${this.parser.parse(token.tokens)}</section>\n`;
        }
    }
};

export default extension