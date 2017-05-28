import Ember from 'ember';

export default Ember.Route.extend({
    model: function () {
        this.store.adapterFor('connection').set('namespace', 'account/confirmed');
        return Ember.RSVP.hash({
            connections: this.store.findAll('connection')
        })
    }
});