import Ember from 'ember';

export default Ember.Route.extend({
    queryParams: {
        id: {
            refreshModel: true
        }
    },
    actions: {
        refresh(){
            this.refresh();
        }
    },
    store: Ember.inject.service(),
    model: function(params) {
        return Ember.RSVP.hash({
            projects: this.modelFor('develop.roadmap').projects,
            teams: this.modelFor('develop.roadmap').teams,
            jobs: this.store.query('job',params,{reload: true}),
            params: params
        });
    },
});
