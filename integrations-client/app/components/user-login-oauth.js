import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    sessionAccount: Ember.inject.service('session-account'),
    routes: Ember.inject.service('route-injection'),
    actions: {
        login(provider) {
            var _this = this;
            this.get('session').authenticate('authenticator:torii', provider).then(function(){
                _this.get('sessionAccount').loadCurrentUser();
                _this.sendAction("refresh");
            }).catch((reason) => {
                console.log(reason);
            });

        }
    }
});
