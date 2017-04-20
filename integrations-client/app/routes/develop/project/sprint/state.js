import Ember from 'ember';

export default Ember.Route.extend({
    store: Ember.inject.service(),
    actions: {

    },
    model: function(params){
        this.store.adapterFor('skillset').set('namespace', 'sprints/' + params.id );
        var all_states = this.store.peekAll('sprint-state');

        return Ember.RSVP.hash({
            events: this.store.query('event', {
                sprint_id: params.id
            }),
            skillsets: this.store.query('skillset', {

            }),
            sprint: this.modelFor("develop.project.sprint").sprint,
            
            states: this.modelFor("develop.project").states,

            project: this.modelFor("develop.project").project,

            selected_state: this.store.peekRecord('sprint-state', params.state_id)
        });
    }
});
