import Ember from 'ember';

export default Ember.Route.extend({
    model: function (params, transition) {
        var id = this.paramsFor('profile').id;
        var store = this.get('store');
        store.adapterFor('request').set('namespace', 'account/' + id);
        var requestPost = store.createRecord('request', {
            contact_id: id
        }).save()
        var requests = this.store.findAll('request');
        return Ember.RSVP.hash({
            requests: requests
        });
    }
});
