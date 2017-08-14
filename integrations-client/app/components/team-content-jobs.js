import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    init() { 
        this._super(...arguments);   
    },
    actions: {
        refresh(){
            this.sendAction("refresh");
        }
    }

});
