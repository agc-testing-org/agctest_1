import Ember from 'ember';

export default Ember.Route.extend({
    model: function () {
    	this.store.adapterFor('connection').set('namespace', 'users/me');
    	var connections = this.store.findAll('connection');
        this.store.adapterFor('connection').set('namespace', '');
        this.store.unloadAll('request'); 
        this.store.adapterFor('request').set('namespace', 'users/me');
        var requests = this.store.findAll('request');
        this.store.adapterFor('request').set('namespace', '');
        return Ember.RSVP.hash({
            connections: connections,
            requests: requests,
            user: this.modelFor("me").user
        });
    }
});
