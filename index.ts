import converter from '@tryghost/html-to-mobiledoc';
import parser from 'xml2json';
import fs from 'fs';
import { createParserPlugins } from './plugins';
import { JSDOM } from 'jsdom';

const plugins = createParserPlugins({
    createDocument(html) {
        let doc = (new JSDOM(html)).window.document;
        return doc;
    }
});

const tags = [
    { id: 1, name: "Build", slug: "build", description: "Posts about build" },
    { id: 2, name: "Testing", slug: "testing", description: "Posts about Testing" },
    { id: 3, name: "Source Control", slug: "sourcecontrol", description: "Posts about Source Control" },
    { id: 4, name: "Docker", slug: "docker", description: "Posts about Docker" },
    { id: 5, name: "DevOps", slug: "devops", description: "Posts about DevOps" },
    { id: 6, name: "Release Manaagement", slug: "releasemanaagement", description: "Posts about Release Manaagement" },
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
    let cats = <any[]>[];
    cats.push(post.categories.category); // TODO: push more categories if this is an array

    const tags = cats.map(c => {
        const lookupTagName = c.toLowerCase().replace(" ", "");
        if (lookupTagName === "teambuild") return 1;
        const lookupTag = tags.filter(t => t.name === lookupTag);
        if (lookupTag) return lookupTagName.id;
        return 15;
    });
    return tags.map(t => {
        return {
            tag_id: t,
            post_id: post.id
        }
    });
}

function getPost(path: string) {
    const xml = fs.readFileSync(path, "utf8");
    const postString = parser.toJson(xml);
    const postObj = JSON.parse(postString);
    const post = postObj.post;
    
    const mobileDocContent = converter.toMobiledoc(post.content, { plugins });
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
        postTags: getTags(post)
    }
}

let posts = <any[]>[];
let postTags = <any[]>[];
// TODO: loop through XML files in 'exported' folder
const postData = getPost("exported/build-fails-path-limit-exceeded.xml");
//const postData2 = getPost("exported/azure-pipeline-parameters.xml");
postTags.push(postData.postTags);
posts.push(postData.post);
// postTags.push(postData2.postTags);
// posts.push(postData2.post);

const gdpost = {
    db: [
        {
            meta: {
                exported_on: new Date().getTime(),
                version: "3.12.1"
            },
            data: {
                posts,
                posts_tags: postData.postTags,
                tags,
            }
        }   
    ]
}

fs.writeFileSync("import.json", JSON.stringify(gdpost));