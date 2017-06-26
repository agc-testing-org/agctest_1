import Ember from 'ember';
import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';

export default Ember.Route.extend(AuthenticatedRouteMixin,{
    actions: {
        error(error, transition) {
            console.log(error);
            if (error && error.errors && error.errors[0].status === '404') {
     //           this.transitionTo('home');
            }
        },
        refresh(){
            console.log("refreshing router");
            this.refresh();
        }
    },
    store: Ember.inject.service(),
    model: function(params) {
        return Ember.RSVP.hash({

        });
    },
});
