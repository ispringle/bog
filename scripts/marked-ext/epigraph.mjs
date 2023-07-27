const regex = /^( {0,3}>> ?(paragraph|[^\n]*)(?:\n|$))+/

const extension = {
    name: 'epigraph',
    level: 'block',
    start(src) {
        return src.match(/>>/)?.index;
    },
    tokenizer(src, _tokens) {
        const cap = regex.exec(src);
        if (cap) {
            const text = cap[0].replace(/^ *>>>[ \t]?/gm, '@footer ').replace(/^ *>>[ \t]?/gm, '');
            const tokens = this.lexer.blockTokens(text);
            return {
                type: 'epigraph',
                raw: cap[0],
                tokens,
                text
            };
        }
    },
    renderer(token) {
        return `<div class="epigraph"><blockquote>${this.parser.parse(token.tokens)}</blockquote></div>`
    }
}

export default extension
