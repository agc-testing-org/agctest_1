import Ember from 'ember';
import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';

export default Ember.Route.extend(AuthenticatedRouteMixin,{
    afterModel(model, transition){
        this.transitionTo("profile.overview",this.paramsFor("profile").id);
    }
});
