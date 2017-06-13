import Ember from 'ember';
import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';

export default Ember.Route.extend({
    afterModel(model,transition) {
        if(model.team.show){
            this.transitionTo('team.select.members');
        }
    }                           
});
