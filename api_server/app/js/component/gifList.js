define(function (require) {
	var handlebars = require('handlebars/handlebars');
	var flight = require('flight/index');
	var itemTemplateSource = require('text!template/list-item.hbs');

	function gifList(){

		this.attributes({
			'urlPrefix': 'http://gjoll.local:5000',
			'pageSize': 20,
			'offset': 0,
			'tagSelector': '.js-tag',
			'postSelector': '.js-post'
		}),

		this.getData = function(){
			var promise = $.ajax({
				url: this.attr.urlPrefix + '/posts',
				data: {
					'offset': this.attr.offset,
					'limit': this.attr.pageSize
				},
				type: 'POST',
				context: this
			});
			promise.done(this.render);

		},

		this.updateTag = function(e){
			var $target = $(e.currentTarget);
			var postId = $target.closest(this.attr.postSelector).attr('id');
			var keyword = $target.val();
			var method = $target.prop( 'checked' ) ? 'PUT' : 'DELETE';
			var promise = $.ajax({
				url: this.attr.urlPrefix + '/' + postId + '/keywords',
				data: keyword,
				type: method,
				context: this
			});
		},

		this.render = function(results){
			var templateItem = handlebars.compile(itemTemplateSource);
			this.$node.html( templateItem(results) );
		},

		// after initializing the component
  		this.after('initialize', function() {
			this.getData();
			this.on('change', {
			    tagSelector: this.updateTag
			});
		});

	}
	return flight.component(gifList);
});