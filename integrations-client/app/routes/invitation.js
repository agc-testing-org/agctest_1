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
    actions: {
        error(error, transition) {
            console.log(error);
            if (error && error.errors && error.errors[0].status === '404') {
                this.transitionTo('home');
            }
        }
    },
    store: Ember.inject.service(),
    model: function(params) {
        return Ember.RSVP.hash({
            token: params.id,
            invitation: this.store.queryRecord('team-invite', {
                token: params.id
            }),
        });
    },
    afterModel(model,transition) {
        if(model.invitation.get("registered")){
            this.transitionTo('registered-invitation',model.token);
        }
    }
});
