import Ember from 'ember';

export default Ember.Route.extend({
    model: function () {
        this.store.adapterFor('notification').set('namespace', 'account');
        var notifications = this.store.findAll('notification');
        this.store.adapterFor('notification').set('namespace', '');

        return Ember.RSVP.hash({
            notifications: notifications
        });
    }
});


