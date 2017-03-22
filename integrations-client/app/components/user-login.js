import Ember from 'ember';

const { inject: { service }, Component } = Ember;

export default Component.extend({
    session: service('session'),
    routes: Ember.inject.service('route-injection'),
    path: "/login",
    errorMessage: null,
    didRender() {
        this._super(...arguments);
        this.$('#register-modal').modal('show');
    },
    actions: {
        login(withRedirect) {
            var email = this.get("email");
            var password = this.get("password");
            var _this = this;
            if(email && (email.length > 5)){
                if(password && (password.length > 7)){
                    var credentials = this.getProperties('email', 'password', 'path');
                    this.get('session').authenticate('authenticator:custom', credentials).catch((reason) => {
                        console.log(reason);
                        this.set('errorMessage', JSON.parse(reason).message);
                    }).then(function(){
                        if(withRedirect){
                            _this.get('routes').redirect("home");
                        }
                    });
                }
            }
        }
    }
});
