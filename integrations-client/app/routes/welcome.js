import Ember from 'ember';
import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';

export default Ember.Route.extend(AuthenticatedRouteMixin,{
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    actions: {
        refresh(){
            console.log("refreshing model");
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
            plans: this.store.findAll('plan'),
            activeRoles: Ember.computed.filterBy("roles","active",true),
            recruiter: Ember.computed.filterBy("activeRoles","name","recruiting"),
            manager: Ember.computed.filterBy("activeRoles","name","management"),
            managerPlan: Ember.computed.filterBy("plans","name","manager"),
//            managerTeams: teams.filterBy('plan_id', parseInt(this.get("managerPlan")[0].id))
        });
    },
});
