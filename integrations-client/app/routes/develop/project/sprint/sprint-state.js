import Ember from 'ember';

export default Ember.Route.extend({
    store: Ember.inject.service(),
    actions: {

    },
    model: function(params){
        this.store.adapterFor('skillset').set('namespace', 'sprints/' + params.id );
        return Ember.RSVP.hash({
            events: this.store.query('event', {
                sprint_id: params.id
            }),
            skillsets: this.store.query('skillset', {

            }),
            sprint: this.store.findRecord('sprint', params.id),
            idea: this.store.peekRecord('state', 1),
            
            states: this.modelFor("develop.project").states,

            project: this.modelFor("develop.project").project,

            selected_state: this.store.peekRecord('sprint-state', params.id),
        });
    }
});
