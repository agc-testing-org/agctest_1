import Ember from 'ember';

const { inject: { service }, RSVP, Service, isEmpty } = Ember;


export default Ember.Service.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
//    intercom: Ember.inject.service('intercom'),

    loadCurrentUser(shouldReload){
        var _this = this;
        return new RSVP.Promise((resolve, reject) => {
            const authenticated = this.get('session.isAuthenticated');
            if (authenticated) {

                console.log("AUTHENTICATED");
                var store = _this.get('store');
                store.adapterFor('session').set('namespace', ''); 
                return store.queryRecord('session',{ reload: shouldReload }).then((account) => {
                    this.set('account',account);

                    /*
                    this.get('intercom').boot({
                        app_id: "isl89nk1",
                        user_id: account.get("id"),
                        name: account.get("username")
                    });
                    */
                    resolve();
                }, reject);

                

            } else {
                resolve();
            }
        });
    }
});
