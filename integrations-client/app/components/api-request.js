import Ember from 'ember';

const { inject: { service }, Component } = Ember;

export default Component.extend({
    session: service('session'),
    actions: {
        request() {
            var _this = this;
            this.get('session').authorize('authorizer:application', (headerName, headerValue) => {
                Ember.$.ajax({                    
                    method: "GET",                                        
                    url: "/facebook",                                                                
                    headers: {                                                                                             
                        'Content-Type': "application/json",                                                                                               
                        'Authorization': headerValue                                                                                                                             
                    }
                }).then(function(response) {                                                                        


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
