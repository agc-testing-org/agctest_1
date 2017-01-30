import Ember from 'ember';

export default Ember.Route.extend({
    store: Ember.inject.service(),
    model: function(params){

        this.store.adapterFor('sprint').set('namespace', 'projects/' + params.name.split("-")[0] );

        return Ember.RSVP.hash({
            project: this.store.findRecord('project', params.name.split("-")[0]),
            sprints: this.store.findAll('sprint')
        });
    }
});
