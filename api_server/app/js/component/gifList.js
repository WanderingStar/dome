define(function (require) {
	var handlebars = require('handlebars/handlebars');
	var flight = require('flight/index');
	var templateSource = require('text!template/list-item.hbs');
	function gifList(){

		this.attributes({
			'dataUrl': 'http://gjoll.local:5000/posts'
		}),

		this.getData = function(){
			var promise = $.ajax({
				url: this.attr.dataUrl,
				data: {
					offset: 100
				},
				type: 'POST',
				context: this
			});
			promise.done(this.render);

		},

		this.render = function(results){
			var template = handlebars.compile(templateSource);
			this.$node.html( template(results) );
		},

		// after initializing the component
  		this.after('initialize', function() {
			this.getData();
		});

	}
	return flight.component(gifList);
});