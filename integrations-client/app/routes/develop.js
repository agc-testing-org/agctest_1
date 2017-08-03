import Ember from 'ember';

export default Ember.Route.extend({
    model: function(params){
        return Ember.RSVP.hash({
            seats: this.store.findAll('seat'),
        });
    }
});
