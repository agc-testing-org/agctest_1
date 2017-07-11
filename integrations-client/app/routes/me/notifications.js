import Ember from 'ember';

export default Ember.Route.extend({
    queryParams: {
        p: {
            refreshModel: true
        }
    },
    model: function (params) {
        this.store.adapterFor('notification').set('namespace', 'users/me');
        var notifications = this.store.query('notification',params);
        this.store.adapterFor('notification').set('namespace', '');

        return Ember.RSVP.hash({
            notifications: notifications,
            params: params
        });
    }
});


