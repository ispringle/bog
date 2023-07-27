const regex =
    /^( {0,3}> ?(?:\[\!(?<calloutKind>\w*)(?:\|(?<calloutTitle>[^\\]]*))?\])[\n|$](?<calloutBody>(?:(?: {0,3}> ?(?:[^\n]*)(?:\n|$))+)){1})/gs
const endReg = /^!!!\s*$/
const debug = false
let config = { nodeName: 'div', className: 'callout', title: { nodeName: 'p' } }
const log = (...args) => debug && console.log(...args)

const extension = {
    name: 'callout',
    level: 'block',
    start(src) {
        return src.match(/\>/)?.index;
    },
    tokenizer(src, _tokens) {
        const match = regex.exec(src)
        if (match) {
            console.log(match)
            log('TOKEN_FUNC:', src, match.join(''))
            const raw = match[0]
            const { calloutKind, calloutTitle, calloutBody } = match.groups
            const token = {
                type: 'callout',
                raw,
                calloutKind,
                calloutTitle,
                calloutBody: calloutBody.replace('>', ''),
                titleTokens: [],
                tokens: [],
                childTokens: ['title', 'text']
            }

            this.lexer.inlineTokens(token.calloutTitle || token.calloutKind, token.titleTokens);
            this.lexer.blockTokens(token.calloutBody, token.tokens);
            return token
        }
    },
    renderer(token) {
        log('RENDER_FUNC:', this, token)
        return `
        <div class="callout callout-${token.calloutKind}>
          <p class="callout-title">${this.parser.parseInline(token.titleTokens)}</p>
          ${this.parser.parse(token.tokens)}
        </div>`
    }
}

export default extension
