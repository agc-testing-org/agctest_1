import Ember from 'ember';

const { inject: { service }, Component } = Ember;

export default Component.extend({
    session: service('session'),
    store: Ember.inject.service(),
    routes: Ember.inject.service('route-injection'),
    registereid: false,
    path: "/accept",
    errorMessage: null,
    didRender() { 
        this._super(...arguments);
        this.$('#register-modal').modal('show');
    },
    actions: {
        role(obj){
            if(obj.get("active") === true){
                obj.set("active",false);
            }
            else {
                obj.set("active",true); 
            }
        },
        accept(){
            var _this = this;
            var password = this.get("password");
            var passwordb = this.get("passwordb");
            var firstName = this.get("firstName");
            if(firstName && firstName.length > 1){
                if(password && (password.length > 7)){
                    if(password === passwordb){
                        var credentials = this.getProperties('token', 'password', 'path','firstName');
                        this.get('session').authenticate('authenticator:custom', credentials).catch((reason) => {
                            var response = JSON.parse(reason).errors[0].detail;
                            _this.set("errorMessage",response);  
                        });
                    }
                    else {
                        this.set('errorMessage', "Passwords do not match");
                    }
                }
                else {
                    this.set('errorMessage', "Password must be 8-30 characters");
                }
            }
            else {
                this.set('errorMessage', "Please enter a first name with more than one character (only letters, numbers, dashes).");
            }
        },
        register() {
            var _this = this;
            var email = this.get("email");
            var firstName = this.get("firstName");
            var lastName = this.get("lastName");

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
                if(firstName && firstName.length > 1){
                    Ember.$.ajax({                    
                        method: "POST",
                        url: "/register",
                        data: JSON.stringify({
                            first_name: firstName,
                            last_name: lastName,
                            email: email,
                            roles: role_array
                        })
                    }).then(function(response) {                                                                        
                        var res = JSON.parse(response);
                        if(res["success"] === true){
                            _this.set("registered",true);
                        }
                        else {

                        }
                    }, function(xhr, status, error) {
                        var response = JSON.parse(xhr.responseText);
                        var response = response.errors[0].detail;
                        _this.set("errorMessage",response);   
                    });
                }
                else {                                           
                    this.set('errorMessage', "Please enter a first name with more than one character (only letters, numbers, dashes).");                  
                } 
            }
            else {                    
                this.set('errorMessage', "Please enter a valid email address.");
            } 
        },
    }
});
