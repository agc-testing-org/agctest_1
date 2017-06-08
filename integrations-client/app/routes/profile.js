import Ember from 'ember';

export default Ember.Route.extend({
    store: Ember.inject.service(),
    model: function(params) {     

        var user = this.store.find('user',params.id);
        this.store.adapterFor('skillset').set('namespace', 'users/'+params.id);

        var skillsets = this.store.findAll('skillset');
        var roles = this.store.findAll('role');
        this.store.adapterFor('skillset').set('namespace', '');

        return Ember.RSVP.hash({
            roles: roles,
            skillsets: skillsets,
            user: user
        });
    }
});
