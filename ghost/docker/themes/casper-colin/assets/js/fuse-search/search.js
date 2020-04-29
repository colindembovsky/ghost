var Model = function() {
  this.exactResults = ko.observableArray([]);
  this.fuzzyResults = ko.observableArray([]);
  this.isBusy = ko.observable(false);
  this.isNew = ko.observable(true);

  this.updateList = function(list, entries) {
    list([]); // clear the list
    entries.forEach(e => list.push(e)); // add each item in
  }

  this.updateResults = function(results) {
    this.isNew(false);
    this.updateList(this.exactResults, results.filter(r => r.score == 1))
    this.updateList(this.fuzzyResults, results.filter(r => r.score < 1))
  }.bind(this);

  this.hasNoResults = ko.pureComputed(function() {
    return this.exactResults().length + this.exactResults().length === 0 && !this.isNew();
  }, this);
};

const baseUrl = `${location.protocol}//${location.host}`;

//return `<a href="${baseUrl}/${val.slug}">${val.title}</a>`;

ko.bindingHandlers.pubDate = {
  update: function (element, valueAccessor, allBindingsAccessor, viewModel) {
    var value = valueAccessor(),
        allBindings = allBindingsAccessor();
    var valueUnwrapped = ko.utils.unwrapObservable(value);        
    var pattern = allBindings.datePattern || 'D MMM YYYY';
    if (valueUnwrapped == undefined || valueUnwrapped == null) {
        $(element).text("");
    }
    else {
        var date = moment(valueUnwrapped);
        $(element).text(`(${moment(date).format(pattern)})`);
    }
  }
};

let model = new Model();
ko.applyBindings(model);

let fuseSearch = new FuseSearch({
    key: 'b944bc1545c0a1db9530c01a82',
    url: 'http://192.168.1.13:3001',
    input: '#search-input',
    results: '#search-results',
    button: '#search-button',
    options: {
      isCaseSensitive: false,
      includeScore: true,
      shouldSort: true,
      // includeMatches: false,
      // findAllMatches: true,
      minMatchCharLength: 3,
      location: 9999999, // high number means match anywhere in the doc
      threshold: 0.5, // lower means more exact
      // distance: 100,
      useExtendedSearch: true,
      keys: [
        {
          name: 'title',
          weight: 0.7
        },
        {
          name: 'plaintext',
          weight: 0.3
        }
      ]
    },
    api: {
      resource: 'posts',
      limit: 'all',
      parameters: { 
          fields: ['title', 'slug', 'published_at', 'plaintext'],
          formats: 'plaintext'
      },
    },
    on: {
      processResults: function(results) {
        // results are sorted worst to best match
        // reverse the order
        return results.reverse();
      },
      processSearchTerm: function(term) {
        // use in conjunction with 'useExtendedSearch'
        // this returns exact matches ('term) or fuzzy matches (term)
        // see https://fusejs.io/api/options.html#advanced-options
        return `'${term} | ${term}`;
      },
      beforeFetch: function() {
        model.isBusy(true);
        NProgress.start();
      },
      afterFetch: function(results) {
        model.isBusy(false);
        NProgress.done();
      },
      drawResults: function(results) {
        model.updateResults(results);
      },
      clearResults: function() {}
    }
});