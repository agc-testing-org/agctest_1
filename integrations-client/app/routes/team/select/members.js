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

        var memberSeat = this.store.peekAll("seat").findBy("name","member");

        this.store.adapterFor('team-comment').set('namespace', 'user-teams/' + this.paramsFor("team.select").id);
        var user_teams_comments = this.store.query('team-comment', {
            seat_id: memberSeatId
        });
        var user_teams_votes = this.store.query('team-vote', {
            seat_id: memberSeatId
        });
        var user_teams_contributors = this.store.query('team-contributor', {
            seat_id: memberSeatId
        });
        var user_teams_comments = this.store.query('team-comments-received', {
            seat_id: memberSeatId
        });
        var user_teams_votes = this.store.query('team-votes-received', {
            seat_id: memberSeatId
        });                                 
        var user_teams_contributors = this.store.query('team-contributors-received', {
            seat_id: memberSeatId       
        }); 
        this.store.adapterFor('team-comment').set('namespace', '');

        return Ember.RSVP.hash({
            team: this.modelFor("team.select").team,
            user_teams_comments: user_teams_comments,
            user_teams: this.store.query('user-team', {
                team_id: this.paramsFor("team.select").id,
                seat_id: memberSeat.get("id")
            }),
            default_seat: memberSeat
        });
    },
});
