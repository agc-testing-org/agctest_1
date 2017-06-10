import Ember from 'ember';
import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';

export default Ember.Route.extend({
    afterModel(model,transition) {
        this.transitionTo('team.new');
    }                           
});
