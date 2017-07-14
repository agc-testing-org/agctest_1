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

        this.store.adapterFor('connection').set('namespace', 'teams/'+this.paramsFor("team.select").id);
        var connections = this.store.findAll('connection');
        this.store.adapterFor('connection').set('namespace', '');

        return Ember.RSVP.hash({
            team: this.modelFor("team.select").team,
            connections: connections
        });
    },
});
