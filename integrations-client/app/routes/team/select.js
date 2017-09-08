import Ember from 'ember';
import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';

export default Ember.Route.extend({
    actions: {
        error(error, transition) {
            console.log(error);
            if (error && error.errors && error.errors[0].status === '404') {
     //           this.transitionTo('home');
            }
        },
        refresh(){
            this.refresh();
        }
    },
    store: Ember.inject.service(),
    model: function(params) {
        return Ember.RSVP.hash({
            team: this.store.findRecord('team',params.id,{reload: true}),
            seats: this.store.findAll('seat'),
            roles: this.store.findAll('role'),
            jobs: this.store.query('job',{
                team_id: this.paramsFor("team.select").id
            },{reload: true}),
        });
    },
});
