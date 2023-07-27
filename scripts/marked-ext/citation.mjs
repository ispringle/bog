// const regex = /^(-{2}(?![\s\n-]))(([^\n-]*)(?:\n+|$))/ // single line citation
// const regex = /(-{2}(?![\s\n-]))((?:(?!-{2})|(?!-{2})[\s\S]*?[^-])\1)/ // multi line citation
const regex = /^(-{2}(?![\s\n-]))(((?!-{2})|(?!-{2}))([\s\S]*?[^-])\1)/ // multi line citation

const extension = {
    name: 'citation',
    level: 'inline',
    start(src) {
        return src.match(/--/)?.index;
    },
    tokenizer(src, _tokens) {
        const cap = regex.exec(src);
        if (cap) {
            const text = cap[4].replace(/\n/g, ' ');
            const tokens = this.lexer.inlineTokens(text);
            return {
                type: 'citation',
                raw: cap[0],
                text,
                tokens,
            };
        }
    },
    renderer(token) {
        return `<cite>${this.parser.parseInline(token.tokens)}</cite>`
    }
}

export default extension
