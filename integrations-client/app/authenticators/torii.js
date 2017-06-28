import Ember from 'ember';
import ToriiAuthenticator from 'ember-simple-auth/authenticators/torii';

export default ToriiAuthenticator.extend({
    torii: Ember.inject.service(),
    session: Ember.inject.service('session'),
    sessionAccount: Ember.inject.service('session-account'),
    authenticate(){
        var _this = this;
        return _this._super(...arguments).then((data) => {
            var header;
            _this.get('session').authorize('authorizer:application', (headerName, headerValue) => {
                header = headerValue;
            });
            console.log("AUTHENTICATING "+data.provider);
            return Ember.$.ajax({
                url: '/session/'+data.provider,
                method: 'POST',
                dataType: 'json',
                headers: {
                    'Content-Type': "application/json",
                    'Authorization': header
                },
                data: JSON.stringify({ 'grant_type': data.provider, 'auth_code': data.authorizationCode })
            }).then((response) => {
                //       this.get('session.data.authenticated').then(function(auth){
                //      auth.set('access_token',response.w7_token);
                //    auth.save();
                //

                return {
                    access_token: response.access_token,
                    provider: data.provider,
                    expires_at: response.expires_at,
                    expires_in: response.expires_in,
                    refresh_token: response.refresh_token
                };
                //                 this.set('session.data.authenticated.access_token',response.w7_token);
                //                   console.log(this.get('session.data.authenticated'));
            });
            });
        }
    });
