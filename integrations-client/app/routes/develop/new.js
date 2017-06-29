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
        },
        refresh(){
            console.log("refreshing router");
            this.refresh();
        }
    },
    model: function(params){
        return Ember.RSVP.hash({
            repositories: this.store.findAll('repository'),
        });
    }
});
