import Ember from 'ember';

export default Ember.Route.extend({
    store: Ember.inject.service(),

    model: function () {

        this.store.adapterFor('connection').set('namespace', 'account/confirmed');
        return Ember.RSVP.hash({
            connection: this.store.findAll('connection')
        })
    }

});
