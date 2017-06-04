import Ember from 'ember';

export default Ember.Route.extend({
    model: function () {
        this.store.adapterFor('request').set('namespace', 'account/connections');
        return Ember.RSVP.hash({
            requests: this.store.findAll('request')
        })
    }
});