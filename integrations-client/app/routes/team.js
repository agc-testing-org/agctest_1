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
            this.refresh();
        }
    },
    store: Ember.inject.service(),
    model: function(params) {
        this.store.adapterFor('me').set('namespace', 'users');
        var user = this.store.queryRecord('me',{});
        this.store.adapterFor('me').set('namespace', '');
        
        return Ember.RSVP.hash({
            user: user
        });
    },
});
