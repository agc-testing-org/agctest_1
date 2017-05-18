import Ember from 'ember';

export default Ember.Route.extend({
    store: Ember.inject.service(),

    beforeModel(){
        var all_states = this.store.peekAll("sprint-state").toArray();
        this.transitionTo('develop.project.sprint.state',all_states[all_states.length - 1].id); 
    }
});
