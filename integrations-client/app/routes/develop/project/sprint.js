import Ember from 'ember';

export default Ember.Route.extend({
    store: Ember.inject.service(),
    actions: {
        refresh(){
            console.log("refreshing router");
            this.refresh();
        }
    },
    model: function(params){
        console.log(this.paramsFor("develop.project").org);
        console.log(this.modelFor("develop.project"));
        console.log(this.modelFor("develop.project").states);

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
            project: this.modelFor("develop.project").project
        });
    }
});
