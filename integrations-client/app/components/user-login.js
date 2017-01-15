import Ember from 'ember';

const { inject: { service }, Component } = Ember;

export default Component.extend({
    session: service('session'),
    path: "/login",
    errorMessage: null,
    actions: {
        login() {
            var email = this.get("email");
            var password = this.get("password");
            if(email && (email.length > 5)){
                if(password && (password.length > 7)){
                    var credentials = this.getProperties('email', 'password', 'path');
                    this.get('session').authenticate('authenticator:custom', credentials).catch((reason) => {
                        console.log(reason);
                        this.set('errorMessage', JSON.parse(reason).message);
                    });
                }
            }
        }
    }
});
