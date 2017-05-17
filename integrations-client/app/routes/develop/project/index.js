import Ember from 'ember';

export default Ember.Route.extend({
    store: Ember.inject.service(),
    beforeModel(){
        this.transitionTo('develop.project.state',"all");
    }
});
