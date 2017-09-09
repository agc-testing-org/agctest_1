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
    afterModel: function() {
        var previousRoutes = this.router.router.currentHandlerInfos;
        var previousRoute = previousRoutes && previousRoutes.pop();
        if(previousRoute && (previousRoute.name === "invitation.index")){
            this.transitionTo("welcome");
        }
    },
    model: function(params) { 
        var store = this.get('store');
        store.adapterFor('clear').set('namespace', ''); //clear namespaces

        var states = this.store.findAll('state');
        var seats = this.store.findAll('seat');

        this.store.adapterFor('me').set('namespace', 'users');
        var user = this.store.queryRecord('me',{});

        this.store.adapterFor('skillset').set('namespace', 'users/me');
        var skillsets = this.store.findAll('skillset'); 
        var roles = this.store.findAll('role');
        var notifications = this.store.query('notification',{
            page: 1
        });
        this.store.adapterFor('skillset').set('namespace', '');

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
            skillsets: skillsets,
            seats: seats,
            notifications: notifications,
            roles: roles,
            user: user,
            states: states,
            params: params,
            me: true,
            comments: comments,
            votes: votes,
            contributors: contributors,
            comments_received: comments_received,
            votes_received: votes_received,
            contributors_received: contributors_received,
        });
    }
});
