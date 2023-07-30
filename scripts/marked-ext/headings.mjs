const titleFound = false;
let subtitleFound = false;

const headingRegex =  /^ {0,3}(#{1,6})(?=\s|$)(.*)(?:\n+|$)/ 

export function headingRenderer(text, level, raw, slugger) {
    const slug = slugger.slug(raw);
    const subtitle = level === 2 && !subtitleFound;
    const tag = subtitle ? "p" : `h${level}`;
    const className = subtitle ? "subtitle" : "";
    subtitleFound = subtitleFound || subtitle;

    const headerEl = `
            <${tag} id="${slug}" class="${className}">
              ${text}
              <a name="${slug}" class="anchor" href="#${slug}">
                <span class="header-link"></span>
              </a>
            </${tag}>`;

    return headerEl
}