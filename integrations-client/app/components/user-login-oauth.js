import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    routes: Ember.inject.service('route-injection'),
    actions: {
        login(provider) {
            var _this = this;
            this.get('session').authenticate('authenticator:torii', provider).then(function(){
                if(provider === "linkedin"){
                    _this.sendAction("refresh");
                }
            }).catch((reason) => {
                console.log(reason);
            });

        }
    }
});
