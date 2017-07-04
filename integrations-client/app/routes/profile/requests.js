import Ember from 'ember';
import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';

export default Ember.Route.extend(AuthenticatedRouteMixin,{
    actions: {
        refresh(){
            this.refresh();
        }
    },
    model: function (params, transition) {
        var id = this.paramsFor('profile').id;
        var store = this.get('store');
        store.adapterFor('request').set('namespace', 'users/' + id);
        var request = this.store.queryRecord('request',{

        });
        store.adapterFor('request').set('namespace', '');
        return Ember.RSVP.hash({
            request: request,
            id: id
        });
    }
});
