import Ember from 'ember';

export default Ember.Route.extend({
    model: function () {
        this.store.adapterFor('request').set('namespace', 'account');
        var requests = this.store.findAll('request');
        this.store.adapterFor('request').set('namespace', '');
        return Ember.RSVP.hash({
            requests: requests
        });
    }
});
