import Ember from 'ember';

export default Ember.Route.extend({
    store: Ember.inject.service(),

    beforeModel(){
        var all_states = this.modelFor("develop.project.sprint").sprint.get("sprint_states").toArray();
        this.transitionTo('develop.project.sprint.state',all_states[all_states.length - 1].id); 
    }
});
