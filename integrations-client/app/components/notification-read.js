import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    actions: {
        readUserNotifications(id, read){

            var store = this.get('store');

            store.adapterFor('notification').set('namespace', 'users/me');

            var notificationRead = store.findRecord('notification', id).then(function (notification) {
                notification.set('read', read);
                notification.save().then(function () {
                     store.adapterFor('notification').set('namespace', '');
                });
            });
        }
    }
});
