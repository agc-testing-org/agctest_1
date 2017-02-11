import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    init() { 
        this._super(...arguments);   
    },
    actions: {
        join(user_id, project_id, sprint_states){
            var _this = this;
            var store = this.get('store');
            store.adapterFor('repository').set('namespace', 'projects/' + project_id );
            console.log(user_id);
            console.log(project_id);
            var sprint_state_array = sprint_states.toArray();

            var project = store.createRecord('repository', {
                sprint_state_id: sprint_state_array[sprint_state_array.length - 1].id
            }).save().then(function() {
                console.log("refreshing");
                _this.sendAction("refresh"); 
            });
        }
    }

});
