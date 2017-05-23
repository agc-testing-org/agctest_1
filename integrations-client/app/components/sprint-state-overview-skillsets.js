import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    actions: {
        updateSkillset(id,sprintId,active){

            var store = this.get('store');

            store.adapterFor('skillset').set('namespace', 'sprints/' + sprintId ); 

            var skillsetUpdate = store.findRecord('skillset',id).then(function(skillset) {
                skillset.set('active', active);
                skillset.save().then(function() {

                });
            });
        }
    }
});
