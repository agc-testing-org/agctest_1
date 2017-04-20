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

            sprint: this.store.findRecord('sprint', params.id),

        });
    }
});
