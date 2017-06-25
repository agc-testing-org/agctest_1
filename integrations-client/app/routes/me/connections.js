import Ember from 'ember';

export default Ember.Route.extend({
    model: function () {
    	this.store.adapterFor('connection').set('namespace', 'users/');
    	var connections = this.store.findAll('connection');
        this.store.adapterFor('connection').set('namespace', '');
        return Ember.RSVP.hash({
            connections: connections
        });
    }
});
