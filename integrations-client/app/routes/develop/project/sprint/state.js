import Ember from 'ember';

export default Ember.Route.extend({
    store: Ember.inject.service(),
    actions: {

    },
    model: function(params){
        this.store.adapterFor('skillset').set('namespace', 'sprints/' + params.id );
        var all_states = this.modelFor("develop.project.sprint").sprint.get("sprint_states").toArray();
        var last_state = {};
        var last_contributor_state = {};
        if(all_states.length > 0){
            last_state = all_states[all_states.length - 1];

            for(var i = 0; i < all_states.length; i++){
                if(all_states[i].id === params.state_id){
                    last_contributor_state = all_states[i - 1]; // state before current 
                }
            }
        }

        return Ember.RSVP.hash({
            events: this.store.query('event', {
                sprint_id: params.id
            }),
            skillsets: this.store.query('skillset', {

            }),
            sprint: this.modelFor("develop.project.sprint").sprint,
            
            states: this.modelFor("develop.project").states,

            project: this.modelFor("develop.project").project,

            selected_state: this.store.peekRecord('sprint-state', params.state_id),

            last_state: last_state,

            last_contributor_state: last_contributor_state

        });
    }
});
