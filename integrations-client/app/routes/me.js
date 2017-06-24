import Ember from 'ember';
import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';

export default Ember.Route.extend(AuthenticatedRouteMixin,{
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),

    actions: {
        refresh(){
            console.log("refreshing router");
            this.refresh();
        }
    },
    model: function(params) { 

        var states = this.store.findAll('state');

        this.store.adapterFor('me').set('namespace', 'users');
        var user = this.store.queryRecord('me',{});

        this.store.adapterFor('skillset').set('namespace', 'users/me');
        var skillsets = this.store.findAll('skillset'); 
        var roles = this.store.findAll('role');
        this.store.adapterFor('skillset').set('namespace', ''); 

        return Ember.RSVP.hash({
            teams: this.store.findAll('team'),
            skillsets: skillsets,
            roles: roles,
            user: user,
            states: states
        });
    }
});
