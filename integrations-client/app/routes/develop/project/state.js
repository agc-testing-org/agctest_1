import Ember from 'ember';

export default Ember.Route.extend({
    store: Ember.inject.service(),
    model: function(params){
        if(params.id === "all"){
            return Ember.RSVP.hash({
                sprints: this.modelFor("develop.project").sprints,
                states: this.modelFor("develop.project").states,
            });
        }
        else {
            return Ember.RSVP.hash({
                sprints: this.store.query('sprint', {
                    project_id: this.modelFor("develop.project").project.id,
                    "sprint_states.state_id": params.id
                }),                             
                states: this.modelFor("develop.project").states,
            });
        }
    }

});
