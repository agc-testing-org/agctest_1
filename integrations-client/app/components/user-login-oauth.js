import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    torii: Ember.inject.service('torii'),
    sessionAccount: Ember.inject.service('session-account'),
    routes: Ember.inject.service('route-injection'),
    path: null,
    auth_code: null,
    headers: null,
    actions: {
        login(provider) {
            var _this = this;

            this.get('torii').open(provider).then(function(authorization){
                _this.set("path",'/session/'+provider);
                _this.set("auth_code",authorization.authorizationCode);

                var header;
                _this.get('session').authorize('authorizer:application', (headerName, headerValue) => {
                    header = headerValue;
                });

                var headers = {
                    'Content-Type': "application/json",
                    'Authorization': header
                };

                _this.set("headers",headers);
                var credentials = _this.getProperties('auth_code', 'path', 'headers');

                return _this.get('session').authenticate('authenticator:custom', credentials).then(function(){
                    _this.get('sessionAccount').loadCurrentUser();
                    _this.sendAction("refresh");  
                }).catch((reason) => {
                    console.log(reason);
                });
            }).catch((reason) => {
                console.log(reason);
            });
        }
    }
});
