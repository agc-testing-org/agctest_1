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
        
        var ldclient = LDClient.initialize('58805b07d051430908d6d570', {"key": "test@example.com"});
        ldclient.on('ready', function() {
            var showFeature = ldclient.variation("submit-project", false);
            if (showFeature) {
                // application code to show the feature
                console.log("show me");
            } else {
                // the code to run if the feature is off
            }
        });
        
    },
    actions: {
        selectProject(owner,repository) {
            this.set("selectedOrg",owner);
            this.set("selectedProject",repository);
        },
        createProject(){
            var org = this.get("selectedOrg");
            var name = this.get("selectedProject");

            var store = this.get('store');
            store.createRecord('project', {
                org: org,
                name: name
            });
            console.log("HERE");

            this.get('session').authorize('authorizer:application', (headerName, headerValue) => {
                Ember.$.ajax({
                    method: "POST",
                    url: "/projects",
                    headers: {
                        'Content-Type': "application/json",
                        'Authorization': headerValue
                    },
                    data: JSON.stringify({
                        org: org,
                        name: name
                    })
                }).then(function(response) {
                    if(response.success){

                    }

                }, function(xhr, status, error) {
                    var response = xhr.responseText;
                });
            });

        }
    }

});
