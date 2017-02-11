import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    sessionAccount: Ember.inject.service('session-account'),
    init() { 

    },
    actions: {
        submit(sprint_state_id){
            var _this = this;
            var store = this.get('store');

            var sprintStateUpdate = store.findRecord('sprint_state',sprint_state_id).then(function(sprintState) {
                sprintState.save().then(function() {
                    console.log("refreshing");
                    _this.sendAction("refresh");
                });
            });
        }
    }
});
