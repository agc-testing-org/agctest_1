import Ember from 'ember';
import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';

export default Ember.Route.extend(AuthenticatedRouteMixin,{
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    queryParams: {
        section: {
            refreshModel: true 
        }
    },
    actions: {
        refresh(){
            this.refresh();
        }
    },
    model: function(params) { 
        return Ember.RSVP.hash({
            params: params,
            teams: this.store.findAll('team'),
            skillsets: this.modelFor("me").skillsets,
            seats: this.modelFor("me").seats,
            notifications: this.modelFor("me").notifications,
            roles: this.modelFor("me").roles,
            user: this.modelFor("me").user,
            states: this.modelFor("me").states
        });
    }
});
