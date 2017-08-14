import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    actions: {
        updateItem(type,itemId,active,namespace){

            var store = this.get('store');

            store.adapterFor(type).set('namespace', namespace); 

            var update = store.findRecord(type,itemId).then(function(item) {
                item.set('active', active);
                item.save().then(function() {
                    store.adapterFor(type).set('namespace', '' );
                });
            });
        }
    }
});
