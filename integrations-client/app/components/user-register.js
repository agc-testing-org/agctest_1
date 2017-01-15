import Ember from 'ember';

const { inject: { service }, Component } = Ember;

export default Component.extend({
    session: service('session'),
    store: Ember.inject.service(),
    routes: Ember.inject.service('route-injection'),
    registered: false,
    actions: {
        role(obj){
            if(obj.get("active") === true){
                obj.set("active",false);
            }
            else {
                obj.set("active",true); 
            }
            console.log(obj.get("name")+ " set to "+obj.get("active"));
        },
        register() {
            var _this = this;
            var email = this.get("email");
            var name = this.get("name");

            var role_ids = this.get('roles').getEach('id');
            var role_actives = this.get('roles').getEach('active');

            var role_array = []; 
            for(var i = 0; i < role_ids.length; i++){
                role_array[role_array.length] = {
                    id: role_ids[i],
                    active: role_actives[i]
                };
            }

            if(email && email.length > 4){
                if(name && name.length > 1){
                    Ember.$.ajax({                    
                        method: "POST",
                        url: "/register",
                        data: JSON.stringify({
                            name: name,
                            email: email,
                            roles: role_array
                        })
                    }).then(function(response) {                                                                        
                        var res = JSON.parse(response);
                        if(res["success"] === true){
                            console.log("REGISTERED");
                            _this.set("registered",true);
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
