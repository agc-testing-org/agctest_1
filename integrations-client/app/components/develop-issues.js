import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
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
        },
        join(user_id, project_id, sprint_states){
            var store = this.get('store');
            this.store.adapterFor('repository').set('namespace', 'projects/' + project_id );
            var project = store.createRecord('repository', {
                sprint_state_id: sprint_states[sprint_states.length - 1]
            }).save();
        }
    }

});
