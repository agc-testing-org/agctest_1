import Ember from 'ember';

export default Ember.Route.extend({
    store: Ember.inject.service(),
    actions: {
        
    },

    model: function(params){

        this.store.adapterFor('skillset').set('namespace', ''); // unset from 

        return Ember.RSVP.hash({
            sprint: this.modelFor("develop.project.sprint").sprint,
            states: this.modelFor("develop.project").states,
            skillsets: this.modelFor("develop.project.sprint").skillsets,
            project: this.modelFor("develop.project").project,
            sprint_states: this.modelFor("develop.project.sprint").sprint_states,
            selected_state: this.store.peekRecord("sprint-state",params.state_id)
        });
    },

    setupController(controller, model) {
        // Call _super for default behavior
        this._super(controller, model);
        var all_states = model.sprint_states.toArray();
        controller.set("last_state",all_states[all_states.length - 1]);

        var last_contributor_state = {};
        for(var i = 0; i < all_states.length; i++){
            if(all_states[i].id === this.paramsFor("develop.project.sprint.state").state_id){
                if(i > 0){                                  
                    last_contributor_state = all_states[i - 1];                                                                
                }                                                                                   
            }                                                           
        }
        controller.set("last_contributor_state",last_contributor_state); 
    }
});
