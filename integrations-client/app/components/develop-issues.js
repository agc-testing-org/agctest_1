import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    sortedSprintStates: Ember.computed.sort('model.sprint_states', 'sortDefinition'),
    sortDefinition: ['created_at:desc'],
    init() { 
        this._super(...arguments);   
    },
    actions: {
        transition(id,transition){
            var store = this.get('store');
            var sprintUpdate = store.findRecord('sprint',id).then(function(sprint) {
                sprint.set('state_id', transition);
                sprint.save(); 
            });
        }
    }

});
