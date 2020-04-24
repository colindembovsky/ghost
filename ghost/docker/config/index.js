// customized from https://github.com/TryGhost/Ghost/blob/master/index.js
// to add Application Insights

// # Ghost Startup
// Orchestrates the startup of Ghost when run from command line.

var startTime = Date.now(),
    debug = require('ghost-ignition').debug('boot:index'),
    sentry = require('./core/server/sentry'),
    ghost, express, common, urlService, parentApp;

debug('First requires...');

ghost = require('./core');

debug('Required ghost');

// add app insights
var appInsightsKey = process.env.APP_INSIGHTS_KEY;
var appInsights = require('applicationinsights');
appInsights.setup(appInsightsKey).start();
debug('Required applicationInsights')

express = require('express');
common = require('./core/server/lib/common');
urlService = require('./core/frontend/services/url');
parentApp = express();

parentApp.use(sentry.requestHandler);

debug('Initialising Ghost');
ghost().then(function (ghostServer) {
    // Mount our Ghost instance on our desired subdirectory path if it exists.
    parentApp.use(urlService.utils.getSubdir(), ghostServer.rootApp);

    debug('Starting Ghost');
    // Let Ghost handle starting our server instance.
    return ghostServer.start(parentApp)
        .then(function afterStart() {
            common.logging.info('Ghost boot', (Date.now() - startTime) / 1000 + 's');
        });
}).catch(function (err) {
    common.logging.error(err);
    setTimeout(() => {
        process.exit(-1);
    }, 100);
});