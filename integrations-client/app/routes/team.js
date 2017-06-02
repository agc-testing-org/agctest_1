import Ember from 'ember';
import UnAuthenticatedRouteMixin from 'ember-simple-auth/mixins/unauthenticated-route-mixin';

export default Ember.Route.extend({
    actions: {
        error(error, transition) {
            console.log(error);
            if (error && error.errors && error.errors[0].status === '404') {
     //           this.transitionTo('home');
            }
        }
    },
    store: Ember.inject.service(),
    model: function(params) {
        return Ember.RSVP.hash({
            team: this.store.find('team',params.id),
            user_teams: this.store.query('user-team', {
                team_id: params.id
            }),
        });
    },
});
