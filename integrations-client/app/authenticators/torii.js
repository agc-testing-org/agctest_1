import Ember from 'ember';
import ToriiAuthenticator from 'ember-simple-auth/authenticators/torii';

export default ToriiAuthenticator.extend({
    torii: Ember.inject.service(),
    authenticate(){
        return this._super(...arguments).then((data) => {
            console.log("AUTHENTICATING "+data.provider);
            return Ember.$.ajax({
                url: '/session/'+data.provider,
                method: 'POST',
                dataType: 'json',
                data: { 'grant_type': data.provider, 'auth_code': data.authorizationCode }
            }).then((response) => {
                //       this.get('session.data.authenticated').then(function(auth){
                //      auth.set('access_token',response.w7_token);
                //    auth.save();
                //
                console.log("AUTHENTICATED "+data.provider);
                return {
                    access_token: response.w7_token,
                    provider: data.provider
                };
                //                 this.set('session.data.authenticated.access_token',response.w7_token);
                //                   console.log(this.get('session.data.authenticated'));
            });
            });
        }
    });
