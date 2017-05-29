import Ember from 'ember';

export default Ember.Route.extend({
	templateName: 'info'
    model: function () {
        this.store.adapterFor('notification').set('namespace', 'account');
        return Ember.RSVP.hash({
            notifications: this.store.findAll('notification')
        });
    }
});
