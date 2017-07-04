import Ember from 'ember';

const { inject: { service }, Component } = Ember;

export default Component.extend({
    session: service('session'),
    actions: {
        logout() {
            var _this = this;
            this.get('session').authorize('authorizer:application', (headerName, headerValue) => {
                Ember.$.ajax({                    
                    method: "DELETE",                                        
                    url: "/session",                                                                
                    headers: {                                                                                             
                        'Content-Type': "application/json",                                                                                               
                        'Authorization': headerValue                                                                                                                             
                    }
                }).then(function(response) {                                                                        
                    Ember.run(function() {
                        _this.get('session').invalidate('authenticator:custom');
                        resolve();
                    });
                }, function(xhr, status, error) {
                    var response = xhr.responseText;
                    Ember.run(function() {
                        reject(response);
                    });
                });
            });
        },
    }
});
