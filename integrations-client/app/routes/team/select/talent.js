import Ember from 'ember';
import UnAuthenticatedRouteMixin from 'ember-simple-auth/mixins/unauthenticated-route-mixin';

export default Ember.Route.extend({
    actions: {
        refresh(){
            this.refresh();
        }
    },
    store: Ember.inject.service(),
    model: function(params) {

        var defaultSeat = null;
        var defaultSeatId = null;
        if(this.modelFor("team.select").team.get("default_seat_id")){
            defaultSeat = this.modelFor("team.select").team.get("default_seat_id");
            defaultSeatId = defaultSeat.get("id");
        }

        var shareSeat = this.store.peekAll("seat").findBy("name","share");

        this.store.adapterFor('team-comment').set('namespace', 'user-teams/' + this.paramsFor("team.select").id);
        var user_teams_comments = this.store.query('team-comment', {
            seat_id: defaultSeatId
        });
        var user_teams_votes = this.store.query('team-vote', {
            seat_id: defaultSeatId
        });
        var user_teams_contributors = this.store.query('team-contributor', {
            seat_id: defaultSeatId
        });
        var user_teams_comments_received = this.store.query('team-comments-received', {
            seat_id: defaultSeatId
        });
        var user_teams_votes_received = this.store.query('team-votes-received', {
            seat_id: defaultSeatId
        });
        var user_teams_contributors_received = this.store.query('team-contributors-received', {
            seat_id: defaultSeatId
        });
        this.store.adapterFor('team-comment').set('namespace', '');


        return Ember.RSVP.hash({
            user_teams_comments: user_teams_comments,
            user_teams_comments_received: user_teams_comments_received,
            user_teams_votes: user_teams_votes,
            user_teams_votes_received: user_teams_votes_received,
            user_teams_contributors: user_teams_contributors,
            user_teams_contributors_received: user_teams_contributors_received,
            team: this.modelFor("team.select").team,
            user_teams: this.store.query('user-team', {
                team_id: this.paramsFor("team.select").id,
                seat_id: defaultSeatId
            }),
            default_seat: defaultSeat,
            share_seat: shareSeat,
            jobs: this.modelFor("team.select").jobs
        });
    },
});
