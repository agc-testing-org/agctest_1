import Ember from 'ember';

export default Ember.Route.extend({
    model: function () {
        this.store.unloadAll('request'); 
        this.store.adapterFor('request').set('namespace', 'users/me');
        var requests = this.store.findAll('request');
        this.store.adapterFor('request').set('namespace', '');
        return Ember.RSVP.hash({
            requests: requests
        });
    }
});
