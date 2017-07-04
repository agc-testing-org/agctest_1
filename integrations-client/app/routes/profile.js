import Ember from 'ember';

export default Ember.Route.extend({
    store: Ember.inject.service(),

    queryParams: {
        skillset_id: {
            refreshModel: true
        },
        role_id: {
            refreshModel: true
        },
    },

    model: function(params) {     
        var states = this.store.findAll('state');
        var user = this.store.find('user',params.id);
        this.store.adapterFor('skillset').set('namespace', 'users/'+params.id);

        var skillsets = this.store.findAll('skillset');
        var roles = this.store.findAll('role');
        var comments = this.get('store').query('aggregate-comment', params);
        var votes = this.get('store').query('aggregate-vote', params);
        this.store.adapterFor('skillset').set('namespace', '');

        return Ember.RSVP.hash({
            roles: roles,
            skillsets: skillsets,
            user: user,
            states: states,
            params: params,
            comments: comments,
            votes: votes
        });
    }
});
