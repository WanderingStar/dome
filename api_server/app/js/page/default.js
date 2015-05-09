define(function (require) {

  'use strict';

  /**
   * Module dependencies
   */

  // var MyComponent = require('component/my_component');
  var gifList = require('component/gifList');

  /**
   * Module exports
   */

  return initialize;

  /**
   * Module function
   */

  function initialize() {
    // MyComponent.attachTo(document);
    gifList.attachTo('.js-list');
  }

});
