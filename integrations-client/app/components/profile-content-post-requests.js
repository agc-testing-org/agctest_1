import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    actions: {
        request(id){
            var _this = this;
            var store = this.get('store');
            store.adapterFor('request').set('namespace', 'users/' + id);
            var requestPost = store.createRecord('request', {
                contact_id: id
            }).save().then(function(payload) { 
                store.adapterFor('request').set('namespace', '');
                _this.sendAction("refresh");
            }); 
        }
    }
});
