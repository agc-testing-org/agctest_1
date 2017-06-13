import Ember from 'ember';

export default Ember.Route.extend({
    model: function (params, transition) {
    	var id = this.paramsFor('profile').id;
    	console.log(id);
    }
});