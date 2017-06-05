import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    actions: {
        filterSkillsets(id){
            //show statistics based on skillset

        }
    }
});
