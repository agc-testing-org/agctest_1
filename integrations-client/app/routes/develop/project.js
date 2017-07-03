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
        var splitUrl = params.project_id.split("-");
        return Ember.RSVP.hash({
            states: this.store.findAll('state'),
            project: this.store.find('project',splitUrl[0])
        });
    }
});
