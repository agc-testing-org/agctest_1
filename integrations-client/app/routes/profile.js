import Ember from 'ember';

export default Ember.Route.extend({
    store: Ember.inject.service(),
    model: function(params) {     
        this.store.adapterFor('skillset').set('namespace', 'account/'+params.id);

        var skillsets = this.store.findAll('skillset');

        this.store.adapterFor('skillset').set('namespace', '');

        return Ember.RSVP.hash({
            skillsets: skillsets
        });
    }
});
