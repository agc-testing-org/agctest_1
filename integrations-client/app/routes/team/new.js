import Ember from 'ember';
import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';

export default Ember.Route.extend({
    actions: {
        error(error, transition) {
            console.log(error);
            if (error && error.errors && error.errors[0].status === '404') {
     //           this.transitionTo('home');
            }
        },
    },
    store: Ember.inject.service(),
    model: function(params) {
        
        this.store.adapterFor('role').set('namespace', 'users/me');
        var roles = this.store.findAll('role');
        this.store.adapterFor('role').set('namespace', '');

        return Ember.RSVP.hash({
            roles: roles,
            user: this.modelFor("team").user,
            plans: this.store.findAll('plan')
        });
    },
});
