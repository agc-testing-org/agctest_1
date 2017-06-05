import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    actions: {
        updateSkillset(id,active){

            var store = this.get('store');

            store.adapterFor('skillset').set('namespace', 'account/'+this.get("sessionAccount.account").id ); 

            var skillsetUpdate = store.findRecord('skillset',id).then(function(skillset) {
                skillset.set('active', active);
                skillset.save().then(function() {
                    store.adapterFor('skillset').set('namespace', '' );
                });
            });
        }
    }
});
