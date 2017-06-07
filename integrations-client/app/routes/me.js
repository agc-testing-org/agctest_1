import Ember from 'ember';
import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';

export default Ember.Route.extend(AuthenticatedRouteMixin,{
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),

    model: function(params) { 

        this.store.adapterFor('skillset').set('namespace', 'account/'+this.get("sessionAccount.account").id);
        var skillsets = this.store.findAll('skillset'); 
        this.store.adapterFor('skillset').set('namespace', ''); 

        return Ember.RSVP.hash({
            teams: this.store.findAll('team'),
            skillsets: skillsets
        });
    }
});
