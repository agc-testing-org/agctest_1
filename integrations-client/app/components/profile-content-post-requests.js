import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    actions: {
        request(id){
            var _this = this;
            var store = this.get('store');
            console.log(id);
            store.adapterFor('request').set('namespace', 'account/' + id);
            var requestPost = store.createRecord('request', {
                contact_id: id
            }).save().then(function(payload) { 
                store.adapterFor('request').set('namespace', '');
                console.log("refreshing");
                _this.sendAction("refresh");
            }); 
        }
    }
});
