import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    actions: {
        postUserConnectionRequests(contact_id){
            console.log(contact_id);
            var store = this.get('store');
            store.adapterFor('requests').set('namespace', 'account');
            var requestPost = store.createRecord('request', {
                contact_id: contact_id
            }).save();
        }
    }
});
