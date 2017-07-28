import Ember from 'ember';

export default Ember.Route.extend({
    queryParams: {
        page: {
            refreshModel: true
        }
    },
    model: function (params) {
        this.store.adapterFor('notifications-setting').set('namespace', 'users/me');
        var notifications_settings = this.store.findAll('notifications-setting'); 
        this.store.adapterFor('notifications-setting').set('namespace', '');

        return Ember.RSVP.hash({
            notifications_settings: notifications_settings
        });
    }
});