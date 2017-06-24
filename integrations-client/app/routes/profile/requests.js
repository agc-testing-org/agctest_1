import Ember from 'ember';

export default Ember.Route.extend({
    actions: {
        refresh(){
            console.log("refreshing router");
            this.refresh();
        }
    },
    model: function (params, transition) {
        var id = this.paramsFor('profile').id;
        var store = this.get('store');
        store.adapterFor('request').set('namespace', 'account/' + id);
        var request = this.store.queryRecord('request',{

        });
        store.adapterFor('request').set('namespace', '');
        return Ember.RSVP.hash({
            request: request,
            id: id
        });
    }
});
