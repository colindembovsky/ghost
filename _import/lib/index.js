"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const html_to_mobiledoc_1 = __importDefault(require("@tryghost/html-to-mobiledoc"));
const xml2json_1 = __importDefault(require("xml2json"));
const fs_1 = __importDefault(require("fs"));
const kg_parser_plugins_1 = require("@tryghost/kg-parser-plugins");
const customPlugins_1 = require("./customPlugins");
const jsdom_1 = require("jsdom");
const axios_1 = __importDefault(require("axios"));
const defaultPlugins = kg_parser_plugins_1.createParserPlugins({
    createDocument(html) {
        let doc = (new jsdom_1.JSDOM(html)).window.document;
        return doc;
    }
});
let plugins = [];
defaultPlugins.forEach(p => {
    if (p.name !== "preCodeToCard" &&
        p.name !== "imgToCard") {
        plugins.push(p);
    }
});
plugins.push(customPlugins_1.preCodeToCardCustom);
plugins.push(customPlugins_1.fontToHtmlCard);
plugins.push(customPlugins_1.imgToCardCustom);
const ALLTAGS = [
    { id: 1, name: "Build", slug: "build", description: "Posts about build" },
    { id: 2, name: "Testing", slug: "testing", description: "Posts about Testing" },
    { id: 3, name: "Source Control", slug: "sourcecontrol", description: "Posts about Source Control" },
    { id: 4, name: "Docker", slug: "docker", description: "Posts about Docker" },
    { id: 5, name: "DevOps", slug: "devops", description: "Posts about DevOps" },
    { id: 6, name: "Release Management", slug: "releasemanagement", description: "Posts about Release Manaagement" },
    { id: 7, name: "Development", slug: "development", description: "Posts about Development" },
    { id: 8, name: "TFS Config", slug: "tfsconfig", description: "Posts about TFS Config" },
    { id: 9, name: "Cloud", slug: "cloud", description: "Posts about Cloud" },
    { id: 10, name: "ALM", slug: "alm", description: "Posts about ALM" },
    { id: 11, name: "AppInsights", slug: "appinsights", description: "Posts about AppInsights" },
    { id: 12, name: "TFS API", slug: "tfsapi", description: "Posts about TFS API" },
    { id: 13, name: "News", slug: "news", description: "Posts about News" },
    { id: 14, name: "Lab Management", slug: "labmanagement", description: "Posts about Lab Management" },
    { id: 15, name: "General", slug: "general", description: "Posts about General topics" },
];
function getTags(post) {
    let cats = [];
    if (Array.isArray(post.categories.category)) {
        cats.push(...post.categories.category);
    }
    else {
        cats.push(post.categories.category);
    }
    const tags = cats.map(c => {
        const lookupTagName = c.toLowerCase().replace(" ", "");
        if (lookupTagName === "teambuild")
            return 1;
        const lookupTag = ALLTAGS.filter(t => t.slug === lookupTagName);
        if (lookupTag.length === 1)
            return lookupTag[0].id;
        return 15;
    });
    return tags.map(t => {
        return {
            tag_id: t,
            post_id: post.id
        };
    });
}
function getComments(post) {
    let comments = post.comments.comment;
    if (!comments)
        return [];
    if (!Array.isArray(comments)) {
        comments = [comments];
    }
    let issoComments = [];
    comments.forEach(c => {
        let issoComment = {
            slug: post.slug,
            text: c.content,
            created: Date.parse(c.date)
        };
        if (c.author !== "Anonymous") {
            issoComment["author"] = c.author;
            if (c.email) {
                issoComment["email"] = c.email;
            }
        }
        if (c.website.length > 0) {
            issoComment["website"] = c.website;
        }
        issoComments.push(issoComment);
    });
    return issoComments;
}
function getPost(path) {
    const xml = fs_1.default.readFileSync(path, "utf8");
    const postString = xml2json_1.default.toJson(xml);
    const postObj = JSON.parse(postString);
    const post = postObj.post;
    console.log("--> Converting " + post.title);
    const mobileDocContent = html_to_mobiledoc_1.default.toMobiledoc(post.content, { plugins });
    const body = JSON.stringify(mobileDocContent);
    return {
        post: {
            id: post.id,
            title: post.title,
            slug: post.slug,
            mobiledoc: body,
            published_at: Date.parse(post.pubDate),
            status: "published",
            published_by: 1
        },
        postTags: getTags(post),
        comments: getComments(post)
    };
}
let posts = [];
let postTags = [];
let comments = [];
const folder = "exported";
var files = fs_1.default.readdirSync(folder);
files.forEach(f => {
    const postData = getPost(folder + "/" + f);
    postTags.push(...postData.postTags);
    posts.push(postData.post);
    comments.push(...postData.comments);
});
const gdpost = {
    db: [
        {
            meta: {
                exported_on: new Date().getTime(),
                version: "3.12.1"
            },
            data: {
                posts,
                posts_tags: postTags,
                tags: ALLTAGS,
            }
        }
    ]
};
// hack the urls for images
const pattern = /http(s?):\/\/colinsalmcorner.com\/posts\/files\//gi;
let importContent = JSON.stringify(gdpost).replace(pattern, "https://colinsalmcorner.azureedge.net/ghostcontent/images/files/");
fs_1.default.writeFileSync("import.json", importContent);
// import comments to isso
const caller = axios_1.default.create({
    baseURL: `http://localhost:3002`,
    headers: { "Content-Type": "application/json" }
});
const waitFor = (ms) => new Promise(r => setTimeout(r, ms));
function asyncForEach(array, callback) {
    return __awaiter(this, void 0, void 0, function* () {
        for (let index = 0; index < array.length; index++) {
            yield callback(array[index], index, array);
        }
    });
}
const importComments = () => __awaiter(void 0, void 0, void 0, function* () {
    yield asyncForEach(comments, (c) => __awaiter(void 0, void 0, void 0, function* () {
        try {
            yield caller.post(`/new?uri=%2F${c.slug.replace("(", "-").replace(")", "-")}%2F`, JSON.stringify(c));
            console.log(".");
        }
        catch (e) {
            console.log(`Failed uploading comment for ${c.slug} by ${c.author ? c.author : 'anonymous'}`);
            console.log(`  --> [${e.response.status}] ${e.response.statusText}`);
            console.log(c.website);
            //console.log(e.response);
        }
        yield waitFor(20);
    }));
});
console.log("Uploading comments!");
importComments();
