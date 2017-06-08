import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    actions: {
        filter(id){
            //show statistics based on skillset and role

        }
    }
});
