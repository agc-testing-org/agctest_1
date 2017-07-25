import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    actions: {
        refresh(){
            this.sendAction("refresh");
        }
    }

});
