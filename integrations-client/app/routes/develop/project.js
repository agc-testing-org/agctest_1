import Ember from 'ember';

export default Ember.Route.extend({
    store: Ember.inject.service(),
    actions: {
        error(error, transition) {
            console.log(error);
            if (error && error.errors && error.errors[0].status === '404') {
               // this.transitionTo('home');
            } else {
                return true;
            }
        }
    },
    model: function(params){

        //        this.store.adapterFor('sprint').set('namespace', 'projects/' + params.name.split("-")[0] );
        //        this.store.adapterFor('sprint-state').set('namespace', 'projects/' + params.name.split("-")[0] );
        this.store.adapterFor('event').set('namespace', 'projects/' + params.name.split("-")[0] );
        return Ember.RSVP.hash({
            states: this.store.findAll('state'),
            project: this.store.find('project',params.name.split("-")[0]),
            events: this.store.findAll('event'),
            //            sprints: this.store.query('sprint', {
            //                project_id: params.name.split("-")[0] 
            //            })
        });
    }
});
