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
        selectProject(owner,repository) {
            this.set("selectedOrg",owner);
            this.set("selectedProject",repository);
        },
        createProject(){
            var org = this.get("selectedOrg");
            var name = this.get("selectedProject");

            console.log(org + " " + name);
            var project = this.get('store').createRecord('project', {
                org: org,
                name: name
            }).save();
        }
    }

});
