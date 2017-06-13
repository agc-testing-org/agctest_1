import Ember from 'ember';
import UnAuthenticatedRouteMixin from 'ember-simple-auth/mixins/unauthenticated-route-mixin';

export default Ember.Route.extend({
    activate () {
        Ember.$('body').addClass('body-dark');
    },                                       
    actions: {
        error(error, transition) {
            console.log(error);
        }
    },
    store: Ember.inject.service(),
    model: function(params) {
        return Ember.RSVP.hash({
            roles: this.store.findAll('role'),
            token: params.id,
            invitation: this.store.queryRecord('team-invite', {
                token: params.id
            }),
        });
    },
    afterModel(model,transition) {
        if(model.invitation.get("sender_email")){ // more than token returned?
            if(model.invitation.get("registered")){
                this.transitionTo('me.invitation',model.token);
            }
        }
        else{
            this.transitionTo('invitation.resend',model.token);
        }
    }
});
