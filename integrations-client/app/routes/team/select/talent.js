import Ember from 'ember';
import UnAuthenticatedRouteMixin from 'ember-simple-auth/mixins/unauthenticated-route-mixin';

export default Ember.Route.extend({
    actions: {
        refresh(){
            console.log("refreshing router");
            this.refresh();
        }
    },
    store: Ember.inject.service(),
    model: function(params) {

        var defaultSeat = this.modelFor("team").team.get("default_seat_id");
        console.log(defaultSeat);

        return Ember.RSVP.hash({
            team: this.modelFor("team").team,
            user_teams: this.store.query('user-team', {
                team_id: this.paramsFor("team").id,
                seat_id: defaultSeat
            }),                                             
        });
    },
});
