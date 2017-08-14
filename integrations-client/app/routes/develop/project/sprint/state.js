import Ember from 'ember';

export default Ember.Route.extend({
    store: Ember.inject.service(),
    actions: {
        
    },

    model: function(params){

        this.store.adapterFor('skillset').set('namespace', ''); // unset from 
        var splitUrl = params.state_id.split("-");
        var job = {};
        var job_id = this.modelFor("develop.project.sprint").sprint.get("job_id");
        if(job_id){
            job = this.store.findRecord("job",job_id);
        }
        return Ember.RSVP.hash({
            job: job,
            sprint: this.modelFor("develop.project.sprint").sprint,
            states: this.modelFor("develop.project").states,
            skillsets: this.modelFor("develop.project.sprint").skillsets,
            project: this.modelFor("develop.project").project,
            sprint_states: this.modelFor("develop.project.sprint").sprint_states,
            selected_state: this.store.peekRecord("sprint-state",splitUrl[0])
        });
    },

    setupController(controller, model) {
        // Call _super for default behavior
        this._super(controller, model);
        var all_states = model.sprint_states.toArray();
        controller.set("last_state",all_states[all_states.length - 1]);
        controller.set("second_to_last_state",all_states[all_states.length - 2]);

        var last_contributor_state = {};
        var splitUrl = this.paramsFor("develop.project.sprint.state").state_id.split("-");
        for(var i = 0; i < all_states.length; i++){
            if(all_states[i].id === splitUrl[0]){
                if(i > 0){                                  
                    last_contributor_state = all_states[i - 1];                                                                
                }                                                                                   
            }
        }
        controller.set("last_contributor_state",last_contributor_state); //prior to current state, not literal last
    }
});
