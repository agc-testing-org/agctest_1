import Ember from 'ember';

export default Ember.Route.extend({
    store: Ember.inject.service(),
    actions: {
        error(error, transition) {
            console.log(error);
            if (error && error.errors[0].status === '404') {
                this.transitionTo('develop.project',this.paramsFor('develop.project').name); 
            } else {
                return true;
            }
        },
        refresh(){
            console.log("refreshing router");
            this.refresh();
        }
    },
    model: function(params){
        this.store.adapterFor('skillset').set('namespace', 'sprints/' + params.id );

        return Ember.RSVP.hash({
            id: params.id,
            states: this.modelFor("develop.project").states,
            sprint: this.store.findRecord('sprint', params.id),
            skillsets: this.store.query('skillset', {

            }),
            sprint_states: this.store.query('sprint-state', {
                sprint_id: params.id
            }),
        });
    }
});
