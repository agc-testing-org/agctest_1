import Ember from 'ember';

export default Ember.Route.extend({
    store: Ember.inject.service(),
    model: function(params){
        console.log(this.paramsFor("develop.project").org);
        console.log(this.modelFor("develop.project"));

        return Ember.RSVP.hash({
            sprint: this.store.peekRecord('sprint', params.id)
        });
    }
});
