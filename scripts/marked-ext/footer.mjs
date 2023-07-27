const regex = /^(@footer ?(paragraph|[^\n]*)(?:\n|$))+/

const extension = {
    name: 'footer',
    level: 'block',
    start(src) {
        return src.match(/@footer/)?.index;
    },
    tokenizer(src, _tokens) {
        const cap = regex.exec(src);
        if (cap) {
            const text = cap[0].replace(/^@footer[ \t]?/gm, '');
            const tokens = this.lexer.inlineTokens(text);
            return {
                type: 'footer',
                raw: cap[0],
                tokens,
                text
            };
        }
    },
    
    renderer(token) {
        return `<footer>${this.parser.parseInline(token.tokens)}</footer>`
    }
}

export default extension
