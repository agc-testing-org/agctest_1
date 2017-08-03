import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    sessionAccount: Ember.inject.service('session-account'),
    errorMessage: null, 
    init() { 
        this._super(...arguments);   
    },
    actions: {
        refresh(){
            this.sendAction("refresh");
        }
    }

});
