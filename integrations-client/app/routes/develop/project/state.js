import Ember from 'ember';

export default Ember.Route.extend({
    store: Ember.inject.service(),
    model: function(params){
        var splitUrl = params.id.split("-");
        if(params.id === "all"){
            return Ember.RSVP.hash({
                project: this.modelFor("develop.project").project,
                sprints: this.store.query('sprint', {
                    project_id: this.modelFor("develop.project").project.id
                }),
                states: this.modelFor("develop.project").states,
                state: {name: "any"}
            });
        }
        else {
            return Ember.RSVP.hash({
                project: this.modelFor("develop.project").project,
                sprints: this.store.query('sprint', {
                    project_id: this.modelFor("develop.project").project.id,
                    "sprint_states.state_id": splitUrl[0]
                }),                             
                states: this.modelFor("develop.project").states,
                state: this.store.peekRecord("state",splitUrl[0])
            });
        }
    }

});
