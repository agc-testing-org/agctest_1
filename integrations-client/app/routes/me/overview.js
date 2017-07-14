import Ember from 'ember';
import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';

export default Ember.Route.extend(AuthenticatedRouteMixin,{
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    actions: {
        refresh(){
            this.refresh();
        }
    },
    model: function(params) { 

        this.store.adapterFor('aggregate-comment').set('namespace', 'users/me');
        var comments = this.get('store').query('aggregate-comment', params);
        var votes = this.get('store').query('aggregate-vote', params);
        var contributors = this.get('store').query('aggregate-contributor', params);
        var comments_received = this.get('store').query('aggregate-comments-received', params);
        var votes_received = this.get('store').query('aggregate-votes-received', params);
        var contributors_received = this.get('store').query('aggregate-contributors-received', params);
        this.store.adapterFor('aggregate-comment').set('namespace', ''); 

        return Ember.RSVP.hash({
            teams: this.store.findAll('team'),
            skillsets: this.modelFor("me").skillsets,
            roles: this.modelFor("me").roles,
            user: this.modelFor("me").user,
            states: this.modelFor("me").states,
            params: params,
            comments: comments,
            votes: votes,
            contributors: contributors,
            comments_received: comments_received,
            votes_received: votes_received,
            contributors_received: contributors_received,
            me: true
        });
    }
});
