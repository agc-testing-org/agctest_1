import Ember from 'ember';
import UnAuthenticatedRouteMixin from 'ember-simple-auth/mixins/unauthenticated-route-mixin';

export default Ember.Route.extend({
    activate () {
        Ember.$('body').addClass('body-dark');
    },                                       
    deactivate () {
        Ember.$('body').removeClass('body-dark');
        Ember.$('#register-modal').modal('hide');
    },    
    store: Ember.inject.service(),
    model: function(params) {
        return Ember.RSVP.hash({
            invite: this.store.find('team-invite',params.id),
            roles: this.store.findAll('role'),
        });
    }
});
