import Ember from 'ember';
import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';

export default Ember.Route.extend(AuthenticatedRouteMixin,{
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    queryParams: {
        section: {
            refreshModel: true 
        }
    },
    actions: {
        refresh(){
            this.refresh();
        }
    },
    model: function(params) { 

        this.store.adapterFor('me').set('namespace', 'users');
        var user = this.store.queryRecord('me',{});
        this.store.adapterFor('me').set('namespace', '');
        
        this.store.adapterFor('skillset').set('namespace', 'users/me');
        var skillsets = this.store.findAll('skillset');
        var roles = this.store.findAll('role');
        this.store.adapterFor('skillset').set('namespace', '');

        return Ember.RSVP.hash({
            params: params,
            user: user,
            teams: this.store.findAll('team'), 
            skillsets: skillsets,
            roles: roles,
            seats: this.store.findAll('seat'),
        });
    }
});
