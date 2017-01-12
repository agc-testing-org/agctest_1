import Ember from 'ember';
import UnAuthenticatedRouteMixin from 'ember-simple-auth/mixins/unauthenticated-route-mixin';

export default Ember.Route.extend({
    store: Ember.inject.service(),
    model: function(params) {
        return Ember.RSVP.hash({
            roles: this.store.findAll('role'),
        });
    }
});
