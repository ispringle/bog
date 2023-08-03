let sectionLevel = 0;
let hgroupSet = false;
let subtitleRendered = false;

const sectionRegexps = new Array(6).fill()
.map((e, i) => new RegExp(`^(#{${i + 2}} )[^]*?(?:\\n(?=\\1)|$)`));
sectionRegexps.unshift(/^(#{1}[ ]?[^\n$]*?[\n$]+(?:#{2}[ ]?[^\n$]*[\n$]){0,1})([^]*(?:\n|$))/)


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
        if (token.level === 1 && token.kind === "hgroup") {
            let preamble = [];
            let body = [];
            let firstHeading = false;
            for (let n in token.tokens) {
                const t = token.tokens[n]
                if (t.type === 'section') {
                    firstHeading = true;
                    body.push(t);
                } else {
                    preamble.push(t)
                }
            }
            const hgroupHTML = token.hgroup.tokens ? `<hgroup>${this.parser.parse(token.hgroup.tokens)}</hgroup>` : "";
            const preambleHTML = preamble ? `<section id=preamble>${this.parser.parse(preamble)}</section>` : "";
            const bodyHTML = body ? this.parser.parse(body) : "";
            // console.log(preambleHTML, bodyHTML)
            return `<article id="content">${hgroupHTML}${preambleHTML}${bodyHTML}</article>`
        } else if (hgroupSet && token.level === 2 && !subtitleRendered) {
            subtitleRendered = true;
            return `${this.parser.parse(token.tokens)}`
        } else {
            const id = this.parser.slugger.slug(`section${token.header}`);
            return `<section id="${id}" class="block level${token.level}">\n${this.parser.parse(token.tokens)}</section>\n`;
        }
    }
};

export default extension