import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    sessionAccount: Ember.inject.service('session-account'),
    sortedSprintStates: Ember.computed.sort('model.sprint_states', 'sortDefinition'),
    sortDefinition: ['created_at:desc'],
    init() { 
        this._super(...arguments);   
    },
    actions: {

    }
});
