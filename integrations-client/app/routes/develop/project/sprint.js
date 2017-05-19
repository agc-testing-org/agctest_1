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
        this.store.adapterFor('skillset').set('namespace', 'sprints/' + params.id );

        return Ember.RSVP.hash({
            id: params.id,
            states: this.modelFor("develop.project").states,
            sprint: this.store.findRecord('sprint', params.id),
            skillsets: this.store.query('skillset', {

            }),
        });
    }
});
