import Ember from 'ember';
import UnAuthenticatedRouteMixin from 'ember-simple-auth/mixins/unauthenticated-route-mixin';

export default Ember.Route.extend({
    activate () {
        Ember.$('body').addClass('body-dark');
    },                                       
    actions: {
        error(error, transition) {
            var detail = error.errors[0].detail;
            console.log(detail);
            if(detail == "this invitation has expired"){
                return true;           
            }
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
        if(model.invitation.get("valid")&&!model.invitation.get("expired")){
            if(model.invitation.get("registered")){
                this.transitionTo('me.invitation',model.token);
            }
        }
        else{
            this.transitionTo('invitation.resend',model.token);
        }
    }
});
