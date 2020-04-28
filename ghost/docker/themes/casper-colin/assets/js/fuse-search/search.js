function createElementFromHTML(htmlString) {
    var div = document.createElement('div');
    div.innerHTML = htmlString.trim();
    return div.firstChild; 
}

function template(result) {
  const url = `${location.protocol}//${location.host}`;
  return `<li><a href="${url}/${result.slug}">${result.title}</a> (${moment(result.published_at).format('D MMM YYYY')})</li>`;
}

function renderList(section, ul, results) {
  console.log("%O", ul);
  if (results.length > 0) {
    results.forEach(r => ul.appendChild(createElementFromHTML(template(r.item))));
    section.show();
  } else {
    section.hide();
  }
}

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
        NProgress.start();
        $('#search-form :input').prop('disabled', true);
      },
      afterFetch: function(results) {
        $('#search-form :input').prop('disabled', false);
        NProgress.done();
      },
      drawResults: function(results) {
        console.log("%O", results);
        console.log(`Found ${results.length} matches`);

        if (results.length == 0) {
          $('#search-results-none').show();
          return;
        }

        const exactMatches = results.filter(r => r.score == 1);
        const fuzzyMatches = results.filter(r => r.score < 1);

        renderList($('#search-results-exact-section'), $('#search-results-exact'), exactMatches);
        renderList($('#search-results-fuzzy-section'), $('#search-results-fuzzy'), fuzzyMatches);
      }
    }
});