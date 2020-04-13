(function ($) {
    'use strict';

    $( document ).ready( function () {
        // {{#if description}}<p class='search-description'>{{description}}</p>{{/if}}
        $("#search-field").ghostHunter({
            results: "#results",
            includebodysearch: true,
            info_template: "<p class='search-results-number'>Matching posts: {{amount}}</p>",
            result_template: "<a id='gh-{{ref}}' class='gh-search-item' href='{{link}}'><h3>{{title}}</h3></a><h4>{{pubDate}}</h4>",
            indexing_start: function() { 
                $('#search-field').prop('disabled', true);
                $('#search-spinner').fadeIn(); 
            },
            indexing_end: function() {
                $('#search-spinner').fadeOut(); 
                $('#search-field').prop('disabled', false).focus();
            },
        });
        $('#close-btn').click( function () {
            $('#search-overlay').fadeOut();
            $('#search-spinner').css({ "display": "block" }); // show the spinner for the next load
        } );
        $('#search-btn').click( function () {
            $('#search-overlay').fadeIn();
            $('#search-field').focus();
        } );

        $(document).keyup(function(e) {
            if (e.keyCode === 27) $('#close-btn').click();   // esc
        });
    } );

}( jQuery ));