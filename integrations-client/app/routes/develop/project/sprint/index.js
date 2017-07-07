import Ember from 'ember';

export default Ember.Route.extend({
    store: Ember.inject.service(),

    model: function(params){
        return Ember.RSVP.hash({
            sprint_states: this.modelFor("develop.project.sprint").sprint_states
        });
    },

    afterModel(model, transition){
        var all = model.sprint_states.toArray();
        this.transitionTo('develop.project.sprint.state',all[all.length - 1].id+"-"+all[all.length - 1].get("state_id.name"));
    }
      
});
