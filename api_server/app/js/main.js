'use strict';

requirejs.config({
  baseUrl: 'bower_components',
  paths: {
    'component': '../js/component',
    'page': '../js/page',
    'template': '../template',
    'text' : 'requirejs-text/text'
  }
});

require(
  [
    'flight/lib/compose',
    'flight/lib/registry',
    'flight/lib/advice',
    'flight/lib/logger',
    'flight/lib/debug'
  ],

  function(compose, registry, advice, withLogging, debug) {
    debug.enable(true);
    compose.mixin(registry, [advice.withAdvice]);

    require(['page/default'], function(initializeDefault) {
      initializeDefault();
    });
  }
);

//to make jQuery play nice with flask and json
$.ajaxSetup({
    contentType : 'application/json',
    processData : false
});
$.ajaxPrefilter( function( options, originalOptions, jqXHR ) {
    if (options.data){
        options.data=JSON.stringify(options.data);
    }
});
