let sectionLevel = 0;
let hgroupSet = false;
let subtitleRendered = false;

const sectionRegexps = new Array(6).fill()
.map((e, i) => new RegExp(`^(#{${i + 2}} )[^]*?(?:\\n(?=\\1)|$)`));
sectionRegexps.unshift(/^(#{1}[ ]?[^\n$]*?[\n$]+?(?:#{2}[ ]?[^\n$]*?\n){0,1})([^]*?(?:\\n(?=\\1)|$))/)


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
            let tokens = this.lexer.blockTokens(match[0]);
            const hgroup = {};
            let kind = "heading"
            if (!hgroupSet && sectionLevel === 1) {
                hgroupSet = true;
                hgroup.tokens = this.lexer.blockTokens(match[1]),
                tokens = this.lexer.blockTokens(match[2]);
                kind = "hgroup"
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