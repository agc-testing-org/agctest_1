import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
       sessionAccount: Ember.inject.service('session-account'),
       store: Ember.inject.service(),
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
