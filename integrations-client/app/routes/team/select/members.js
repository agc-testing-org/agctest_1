import Ember from 'ember';
import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';

export default Ember.Route.extend({
    actions: {
        refresh(){
            this.refresh();
        }
    },
    store: Ember.inject.service(),
    model: function(params) {

        var memberSeatId = this.store.peekAll("seat").findBy("name","member").get("id");

        return Ember.RSVP.hash({
            team: this.modelFor("team.select").team,
            user_teams: this.store.query('user-team', {
                team_id: this.paramsFor("team.select").id,
                seat_id: memberSeatId
            }),
            default_seat_id: memberSeatId
        });
    },
});
