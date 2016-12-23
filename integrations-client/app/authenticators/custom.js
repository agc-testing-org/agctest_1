import Ember from 'ember';
import Base from 'ember-simple-auth/authenticators/base';

export default Base.extend({
    restore: function(data) {
        return new Ember.RSVP.Promise(function(resolve, reject) {
            if (!Ember.isEmpty(data.access_token)) {
                resolve(data);
            } else {
                reject();
            }
        });
    },

    authenticate: function(options) {
        console.log("AUTHENTICATING WIRED7");
        return new Ember.RSVP.Promise((resolve, reject) => {
            Ember.$.ajax({
                url: options.path,
                type: 'POST',
                data: JSON.stringify({
                    name: options.name,
                    email: options.email,
                    password: options.password
                }),
                contentType: 'application/json;charset=utf-8',
                dataType: 'json'
            }).then(function(response) {
                Ember.run(function() {
                    console.log("AUTHENTICATED WIRED7");
                    resolve({
                        access_token: response.w7_token
                    });
                });
            }, function(xhr, status, error) {
                var response = xhr.responseText;
                Ember.run(function() {
                    reject(response);
                });
            });
        });
    },

    invalidate: function() {
        console.log("SIGNED OUT");
        return Ember.RSVP.resolve();
    }
});
