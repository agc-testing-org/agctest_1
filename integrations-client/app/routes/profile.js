import Ember from 'ember';

export default Ember.Route.extend({
    store: Ember.inject.service(),
    model: function(params) {     
        this.store.adapterFor('skillset').set('namespace', 'users/'+params.id);

        var skillsets = this.store.findAll('skillset');
        var user = this.store.find('user','me');
        this.store.adapterFor('skillset').set('namespace', '');

        return Ember.RSVP.hash({
            skillsets: skillsets,
            user: user
        });
    }
});
