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
            params: params,
            comments: this.modelFor("me").comments,
            votes: this.modelFor("me").votes,
            contributors: this.modelFor("me").contributors,
            comments_received: this.modelFor("me").comments_received,
            votes_received: this.modelFor("me").votes_received,
            contributors_received: this.modelFor("me").contributors_received,
        });
    }
});


