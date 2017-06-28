import Ember from 'ember';
import LDClient from 'npm:ldclient-js';


export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    selectedProject: null,
    selectedOrg: null,
    init() { 
        this._super(...arguments);   
    },
    actions: {
        refresh(){
            this.sendAction("refresh");
        }
    }

});
