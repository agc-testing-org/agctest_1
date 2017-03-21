import Ember from 'ember';

const { inject: { service }, Component } = Ember;

export default Component.extend({
    session: service('session'),

    errorMessage: null,
    didRender() {
        this._super(...arguments);
        this.$('#register-modal').modal('show');
    },   
    actions: {
        reset() {
            var email = this.get("email");
            if(email && (email.length > 5)){
                Ember.$.ajax({
                    method: "POST",
                    url: "/forgot",
                    data: JSON.stringify({
                        email: email
                    })
                }).then(function(response) {
                    var res = JSON.parse(response);
                    if(res["success"] === true){
                        this.set('errorMessage', "A reset link will be sent to "+email);
                    }
                }, function(xhr, status, error) {
                    var response = xhr.responseText;
                    Ember.run(function() {
                        reject(response);
                    });
                });

            }
            else {
                this.set('errorMessage', "Please enter a valid email");
            }
        },
    }
});
