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
            user: this.modelFor("team").user,
            team: this.modelFor("team.select").team,
            roles: this.store.findAll('role'),
            jobs: this.modelFor("team.select").jobs
        });
    }
});
