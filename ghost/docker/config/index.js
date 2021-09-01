// add app insights
var appInsightsKey = process.env.APP_INSIGHTS_KEY;
var appInsights = require('applicationinsights');
appInsights.setup(appInsightsKey).start();

// original contents below:
require('./ghost');
