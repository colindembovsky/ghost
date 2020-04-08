"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
function preCodeToCardCustom(node, builder, { addSection, nodeFinished }) {
    if (node.nodeType !== 1 || node.tagName !== 'PRE') {
        return;
    }
    //console.log("--> preCodeToCard invoked");
    let payload = { code: node.innerHTML, language: "" };
    let brushLangRegex = /brush:(.*?)(:\s|$|")/i;
    let preClass = node.getAttribute('class') || '';
    let brushMatches = preClass.match(brushLangRegex);
    if (brushMatches) {
        payload.language = brushMatches[1].toLowerCase().trim();
    }
    let cardSection = builder.createCardSection('code', payload);
    addSection(cardSection);
    nodeFinished();
}
exports.preCodeToCardCustom = preCodeToCardCustom;
function imgToCardCustom(node, builder, { addSection, nodeFinished }) {
    if (node.nodeType !== 1 || node.tagName !== 'IMG') {
        return;
    }
    console.log("--> imgToCardCustom invoked");
    let cardSection;
    if (node.parentNode.tagName === "A") {
        cardSection = builder.createCardSection('html', { html: node.parentNode.outerHTML });
    }
    else {
        let payload = {
            src: node.src,
            alt: node.alt,
            title: node.title
        };
        cardSection = builder.createCardSection('image', payload);
    }
    addSection(cardSection);
    nodeFinished();
}
exports.imgToCardCustom = imgToCardCustom;
function fontToHtmlCard(node, builder, { addSection, nodeFinished }) {
    if (node.nodeType !== 1 || node.tagName !== 'FONT') {
        return;
    }
    //console.log("--> fontToHtmlCard invoked");
    let payload = { html: node.outerHTML };
    let cardSection = builder.createCardSection('html', payload);
    addSection(cardSection);
    nodeFinished();
}
exports.fontToHtmlCard = fontToHtmlCard;
