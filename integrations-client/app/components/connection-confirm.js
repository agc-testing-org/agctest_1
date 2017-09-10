import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    actions: {
        refresh(){
            this.sendAction("refresh");
        },  
        confirmeUserConnectionRequests(id, confirmed){

            var _this = this;
            var store = this.get('store');

            store.adapterFor('connections').set('namespace', 'users/me');

            var requestConfirme = store.findRecord('connection', id).then(function (connection) {
                connection.set('confirmed', confirmed);
                connection.set('read', 1);
                connection.save().then(function () {
                    store.adapterFor('connections').set('namespace', '');
                    _this.sendAction("refresh");
                });
            });
        }
    }
});
