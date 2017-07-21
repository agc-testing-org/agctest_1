import Ember from 'ember';

export default Ember.Route.extend({
    queryParams: {
        page: {
            refreshModel: true
        }
    },
    model: function (params) {
        var states = this.store.findAll('state');
        var id = this.paramsFor("team.select").id
        this.store.adapterFor('notification').set('namespace', 'teams/'+id);
        var notifications = this.store.query('notification',params);
        this.store.adapterFor('notification').set('namespace', '');

        return Ember.RSVP.hash({
            notifications: notifications,
            params: params,
            states: states
        });
    }
});

