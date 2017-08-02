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
        return Ember.RSVP.hash({
            team: this.modelFor("team.select").team,
            jobs: this.store.query('job',{
                team_id: this.paramsFor("team.select").id
            },{reload: true}),
        });
    }
});
