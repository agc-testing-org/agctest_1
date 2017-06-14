import Ember from 'ember';

export default Ember.Route.extend({
    model: function (params, transition) {
        var id = this.paramsFor('profile').id;
        console.log(id);
        var store = this.get('store');
        store.adapterFor('requests').set('namespace', 'account');
        var requestPost = store.createRecord('request', {
            contact_id: id
        }).save()
    }
});
