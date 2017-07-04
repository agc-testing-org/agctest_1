import Ember from 'ember';
import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';

export default Ember.Route.extend(AuthenticatedRouteMixin,{
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    queryParams: {
        skillset_id: {
            refreshModel: true
        },
        role_id: {
            refreshModel: true
        },    
    },
    actions: {
        refresh(){
            this.refresh();
        }
    },
    model: function(params) { 

        var states = this.store.findAll('state');

        this.store.adapterFor('me').set('namespace', 'users');
        var user = this.store.queryRecord('me',{});

        this.store.adapterFor('skillset').set('namespace', 'users/me');
        var skillsets = this.store.findAll('skillset'); 
        var roles = this.store.findAll('role');
        var comments = this.get('store').query('comment', params);
        var votes = this.get('store').query('vote', params);
//        var contributors = this.get('store').query('contributor', params);
//        var comments_received = this.get('store').query('comments-received', params);
//        var votes_received = this.get('store').query('votes-received', params);
//        var contributors_received = this.get('store').query('contributors-received', params);

        this.store.adapterFor('skillset').set('namespace', ''); 

        return Ember.RSVP.hash({
            teams: this.store.findAll('team'),
            skillsets: skillsets,
            roles: roles,
            user: user,
            states: states,
            params: params,
            comments: comments,
            votes: votes,
//            contributors: contributors,
//            comments_received: comments_received,
//            votes_received: votes_received,
//            contributors_received: contributors_received
        });
    }
});
