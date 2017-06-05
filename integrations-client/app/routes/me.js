import Ember from 'ember';
import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';

export default Ember.Route.extend(AuthenticatedRouteMixin,{
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    model: function(params) { 
       
        var teams = this.store.findAll('team');

        this.store.adapterFor('skillset').set('namespace', 'account/'+this.get("sessionAccount.account").id); 

        return Ember.RSVP.hash({
            skillsets: this.store.findAll('skillset'),
            teams: teams
        });
    }
});
