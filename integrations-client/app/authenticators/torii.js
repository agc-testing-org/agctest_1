import Ember from 'ember';
import ToriiAuthenticator from 'ember-simple-auth/authenticators/torii';

export default ToriiAuthenticator.extend({
    torii: Ember.inject.service(),
    session: Ember.inject.service('session'),
    sessionAccount: Ember.inject.service('session-account'),
    path: null,
    grant_type: null,
    auth_code: null,
    headers: null,
    authenticate(){
        var _this = this;
        return _this._super(...arguments).then((data) => {

            var header;
            _this.get('session').authorize('authorizer:application', (headerName, headerValue) => {
                header = headerValue;
            });

            var headers = {
                'Content-Type': "application/json",
                'Authorization': header
            };

            this.set("auth_code",data.authorizationCode);
            this.set("grant_type",data.provider);
            this.set("path",'/session/'+data.provider);

            this.set("headers",headers);
            var credentials = this.getProperties('auth_code', 'grant_type', 'path', 'headers');

            return this.get('session').authenticate('authenticator:custom', credentials).catch((reason) => {
                this.set('errorMessage', JSON.parse(reason).message);
            }).then(function(){
                return {
                    access_token: _this.get('session.data.authenticated.access_token'),
                    refresh_token: _this.get('session.data.authenticated.refresh_token'),
                    expires_at: _this.get('session.data.authenticated.expires_at'),
                    expires_in: _this.get('session.data.authenticated.expires_in'),
                    authenticator: "authenticator:custom",
                    provider: data.provider
                };
            });

        });
    }
});
