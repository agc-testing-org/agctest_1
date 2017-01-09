import Ember from 'ember';

const { inject: { service }, Component } = Ember;

export default Component.extend({
    session: service('session'),
    routes: Ember.inject.service('route-injection'),
    actions: {
        register() {
            var _this = this;
            var email = this.get("email");
            var name = this.get("name");

            if(email && email.length > 4){
                if(name && name.length > 1){
                    Ember.$.ajax({                    
                        method: "POST",                                        
                        url: "/register", 
                        data: JSON.stringify({
                            name: name,
                            email: email
                        })
                    }).then(function(response) {                                                                        
                        var res = JSON.parse(response);
                        if(res["success"] === true){
                            console.log("REGISTERED");
                        }
                        else {

                        }
                    }, function(xhr, status, error) {
                        var response = xhr.responseText;
                        Ember.run(function() {
                            reject(response);
                        });
                    });
                }
            }
        },
    }
});
