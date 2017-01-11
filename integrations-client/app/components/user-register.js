import Ember from 'ember';

const { inject: { service }, Component } = Ember;

export default Component.extend({
    session: service('session'),
    routes: Ember.inject.service('route-injection'),
    product: false,
    design: false,
    development: false,
    quality: false,
    actions: {
        role(type){
            if(this.get(type)){
                this.set(type,false);
            }
            else {
                this.set(type,true);
            }
            console.log(type+" set to "+this.get(type));
        },
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
                            email: email,
                            roles: {
                                product: { 
                                    active: this.get("product"),
                                    id: 1 //TODO
                                },
                                design: {
                                    active: this.get("design"),
                                    id: 2
                                },
                                development: {
                                    active: this.get("development"),
                                    id: 3
                                },
                                quality: {
                                    active: this.get("quality"),
                                    id: 4
                                }
                            }
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
