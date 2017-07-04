import Ember from 'ember';

export default Ember.Route.extend({
    store: Ember.inject.service(),
    afterModel(model, transition){
        this.transitionTo('develop.project.state',"all");
    }
});
