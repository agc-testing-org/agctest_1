import Ember from 'ember';

const { inject: { service }, Component } = Ember;

export default Component.extend({
    session: service('session'),
    message:null,
    showResend: true,
    init(){
        this._super(...arguments);
    },
    didRender() {
        this._super(...arguments);
        this.$('#register-modal').modal('show');
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
                    _this.set("message", "A new invitation will be sent to the associated email address");
                    _this.set("showResend", false);
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
