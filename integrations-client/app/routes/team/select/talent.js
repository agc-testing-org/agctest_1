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

        var defaultSeat = null;
        if(this.modelFor("team.select").team.get("default_seat_id")){
            defaultSeat = this.modelFor("team.select").team.get("default_seat_id");
        }

        return Ember.RSVP.hash({
            team: this.modelFor("team.select").team,
            user_teams: this.store.query('user-team', {
                team_id: this.paramsFor("team.select").id,
                seat_id: defaultSeat
            }),                                             
        });
    },
});
