import Ember from 'ember';
import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';

export default Ember.Route.extend(AuthenticatedRouteMixin,{
    store: Ember.inject.service(),
    model: function(params) { 
        return Ember.RSVP.hash({
            teams: this.store.findAll('team')
        });
    }
});
