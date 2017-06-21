import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    mergedStates: Ember.computed.filterBy('sprint.sprint_states','merged', true),
    actions: {
        refresh(){
            this.sendAction("refresh");
        }
    }
});
