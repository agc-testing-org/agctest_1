import Ember from 'ember';
import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';

export default Ember.Route.extend(AuthenticatedRouteMixin,{
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    actions: {
//        refresh(){
//            this.refresh(); // let parent handle 
//        }
    },
    model: function(params) { 

        return Ember.RSVP.hash({
            teams: this.store.findAll('team'),
            skillsets: this.modelFor("me").skillsets,
            roles: this.modelFor("me").roles,
            user: this.modelFor("me").user,
            states: this.modelFor("me").states,
            params: params,
            comments: this.modelFor("me").comments,
            votes: this.modelFor("me").votes,
            contributors: this.modelFor("me").contributors,
            comments_received: this.modelFor("me").comments_received,
            votes_received: this.modelFor("me").votes_received,
            contributors_received: this.modelFor("me").contributors_received,
            me: true
        });
    }
});
