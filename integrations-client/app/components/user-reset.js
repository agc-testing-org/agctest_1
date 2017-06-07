import Ember from 'ember';

const { inject: { service }, Component } = Ember;

export default Component.extend({
    session: service('session'),
    path: "/reset",
    errorMessage: null,
    didRender() {
        this._super(...arguments);
        this.$('#register-modal').modal('show');
    },
    init(){
        this._super(...arguments);
    },
    actions: {
        reset() {
            var password = this.get("password");
            var passwordb = this.get("passwordb");
            if(password && (password.length > 7)){
                if(password === passwordb){
                    var credentials = this.getProperties('token', 'password', 'path');
                    this.get('session').authenticate('authenticator:custom', credentials).catch((reason) => {
                        console.log(reason);
                        this.set('errorMessage', JSON.parse(reason).message);
                    });
                }
                else {
                    this.set('errorMessage', "Passwords do not match");
                }
            }
            else {
                this.set('errorMessage', "Password must be 8-30 characters");
            }
        },
    }
});
