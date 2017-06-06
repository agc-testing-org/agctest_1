import Ember from 'ember';

const { inject: { service }, Component } = Ember;

export default Component.extend({
    session: service('session'),
    message:"This invite is invalid or has expired",
    didRender() {
        this._super(...arguments);
        this.$('#register-modal').modal('show');
    },
    init(){
        this._super(...arguments);
    },
    actions: {
        resend(token) {
            var _this = this;
            Ember.$.ajax({
                method: "POST",
                url: "/resend",
                data: JSON.stringify({
                    token: token
                })
            }).then(function(response) {
                var res = JSON.parse(response);
                if(res["success"] === true){
                    _this.set('message', "A new invite will be sent to the email address associated with the invite");
                }
            }, function(xhr, status, error) {
                var response = xhr.responseText;
                Ember.run(function() {
                    reject(response);
                });
            });
        },
    }
});
