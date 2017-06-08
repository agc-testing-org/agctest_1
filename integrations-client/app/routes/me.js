import Ember from 'ember';
import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';

export default Ember.Route.extend(AuthenticatedRouteMixin,{
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),

    model: function(params) { 

        this.store.adapterFor('skillset').set('namespace', 'users/me');
        var skillsets = this.store.findAll('skillset'); 
        var user = this.store.find('user','me');
        this.store.adapterFor('skillset').set('namespace', ''); 

        return Ember.RSVP.hash({
            teams: this.store.findAll('team'),
            skillsets: skillsets,
            user: user
        });
    }
});
