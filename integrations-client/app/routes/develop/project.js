import Ember from 'ember';

export default Ember.Route.extend({
    store: Ember.inject.service(),
    model: function(params){

        this.store.adapterFor('sprint').set('namespace', 'projects/' + params.name.split("-")[0] );
        this.store.adapterFor('sprint-state').set('namespace', 'projects/' + params.name.split("-")[0] );
        this.store.adapterFor('event').set('namespace', 'projects/' + params.name.split("-")[0] );
        return Ember.RSVP.hash({
            states: this.store.findAll('state'),
            project: this.store.findRecord('project', params.name.split("-")[0]),
            events: this.store.findAll('event'),
            sprints: this.store.findAll('sprint'),
            sprint_states: this.store.query('sprint-state', {

            })
        });
    }
});
