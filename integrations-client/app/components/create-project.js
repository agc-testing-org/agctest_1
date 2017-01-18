import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    selectedProject: null,
    selectedOrg: null,
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
