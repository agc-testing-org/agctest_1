import Ember from 'ember';

export default Ember.Route.extend({
    model: function(params){
        this.store.adapterFor('clear').set('namespace', ''); //clear namespaces
        return Ember.RSVP.hash({
            seats: this.store.findAll('seat'),
        });
    }
});
