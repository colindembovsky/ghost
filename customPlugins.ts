export function preCodeToCardCustom(node, builder, {addSection, nodeFinished}) {
    if (node.nodeType !== 1 || node.tagName !== 'PRE') {
        return;
    }
    console.log("--> preCodeToCard invoked");
    
    let payload = {code: node.innerHTML, language: "" };

    let brushLangRegex = /brush:(.*?)(:\s|$|")/i
    let preClass = node.getAttribute('class') || '';
    let brushMatches = preClass.match(brushLangRegex);
    if (brushMatches) {
        payload.language = brushMatches[1].toLowerCase().trim();
    }
    let cardSection = builder.createCardSection('code', payload);
    addSection(cardSection);
    nodeFinished();
}

export function fontToHtmlCard(node, builder, {addSection, nodeFinished}) {
    if (node.nodeType !== 1 || node.tagName !== 'FONT') {
        return;
    }
    console.log("--> fontToHtmlCard invoked");
    
    let payload = { html: node.outerHTML };
    let cardSection = builder.createCardSection('html', payload);
    addSection(cardSection);
    nodeFinished();
}