import Ember from 'ember';

export default Ember.Route.extend({
    
    model: function () {

        this.store.adapterFor('connection').set('namespace', 'users/me');
        var connections = this.store.query('connection',{});
        this.store.adapterFor('connection').set('namespace', '');

        return Ember.RSVP.hash({
            connections: connections,
            user: this.modelFor("me").user
        });
    }
});
