import Ember from 'ember';

export default Ember.Route.extend({
    store: Ember.inject.service(),
    actions: {
        error(error, transition) {
            console.log(error);
            if (error && error.errors && error.errors[0].status === '404') {
                this.transitionTo('develop.project',this.paramsFor('develop.project').name); 
            } else {
                return true;
            }
        },
        refresh(){
            this.refresh();
        }
    },
    model: function(params){

        this.store.adapterFor('skillset').set('namespace', 'sprints/' + params.id );
        var skillsets = this.store.query('skillset', {});
        this.store.adapterFor('skillset').set('namespace','');

        return Ember.RSVP.hash({
            id: params.id,
            project: this.modelFor("develop.project").project,
            states: this.modelFor("develop.project").states,
            sprint: this.store.findRecord('sprint', params.id),
            skillsets: skillsets, 
            sprint_states: this.store.query('sprint-state', {
                sprint_id: params.id
            }),
        });
    }
});
