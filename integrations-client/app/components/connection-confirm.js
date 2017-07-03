import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    actions: {
        confirmeUserConnectionRequests(id, confirmed){

            var store = this.get('store');

            store.adapterFor('requests').set('namespace', 'users/me');

            var requestConfirme = store.findRecord('request', id).then(function (request) {
                request.set('confirmed', confirmed);
                request.save().then(function () {
                    store.adapterFor('requests').set('namespace', '');
                });
            });
        }
    }
});
