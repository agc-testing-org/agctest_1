import Ember from 'ember';

export default Ember.Route.extend({
    actions: {
        refresh(){
            this.refresh();
        }
    },
    store: Ember.inject.service(),
    model: function(params) {
        var splitUrl = params.id.split("-");
        return Ember.RSVP.hash({
            projects: this.modelFor('develop.roadmap').projects,
            teams: this.modelFor('develop.roadmap').teams,
            job: this.store.findRecord('job',splitUrl[0]),
        });
    },
});
