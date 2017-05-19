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
            selected_state: this.store.peekRecord("sprint-state",params.state_id),
            state_id: params.state_id
        });
    },
    afterModel(model, transition) {

        // We could handle this w/ error handling for a 404
        //        if(!this.store.peekRecord("sprint-state",model.state_id)){
        //   this.transitionTo('develop.project.sprint.state',ss[ss.length - 1]);
        //      }
    },

    setupController(controller, model) {
        // Call _super for default behavior
        this._super(controller, model);
    }
});
