import Ember from 'ember';

export default Ember.Route.extend({
    queryParams: {
        page: {
            refreshModel: true
        }
    },
    model: function (params) {
        this.store.adapterFor('notification').set('namespace', 'users/me');
        var notifications = this.store.query('notification',params);
        this.store.adapterFor('notification').set('namespace', '');

        return Ember.RSVP.hash({
            notifications: notifications,
            skillsets: this.modelFor("me").skillsets,
            roles: this.modelFor("me").roles,
            user: this.modelFor("me").user,
            params: params
        });
    }
});


