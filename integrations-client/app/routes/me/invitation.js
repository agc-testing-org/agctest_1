import Ember from 'ember';
import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';

export default Ember.Route.extend(AuthenticatedRouteMixin,{
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
    beforeModel(transition) {
        this._super(transition);
        let loginController = this.controllerFor('login');
        loginController.set('previousTransition', transition);
    },
    afterModel(model,transition) {
        if(!model.invitation.get("sender_email")){ // more than token returned?
            this.transitionTo('invitation.resend',model.token);
        }
    }
});
