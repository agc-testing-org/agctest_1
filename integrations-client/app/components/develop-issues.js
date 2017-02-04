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
        join(user_id, state_id){
            var store = this.get('store');
            store.adapterFor('join').set('namespace', 'sprint_states/' + state_id );

            var project = store.createRecord('join', {
                user_id: user_id
            }).save();
        }
    }

});
