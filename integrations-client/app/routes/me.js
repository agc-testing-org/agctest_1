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

        return Ember.RSVP.hash({
            teams: this.store.findAll('team'),
            skillsets: skillsets,
            seats: seats,
            notifications: notifications,
            roles: roles,
            user: user,
            states: states,
            params: params,
            me: true
        });
    }
});
