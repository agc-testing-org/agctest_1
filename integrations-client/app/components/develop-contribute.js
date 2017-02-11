import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    sessionAccount: Ember.inject.service('session-account'),
    store: Ember.inject.service(),
    actions: {
        submit(project_id, sprint_state_id){
            var _this = this;
            var store = this.get('store');

            store.adapterFor('contributor').set('namespace', 'projects/' + project_id );
            var contributorUpdate = store.findRecord('contributor',sprint_state_id).then(function(contributor) {
                contributor.save().then(function() {
                    console.log("refreshing");
                    _this.sendAction("refresh");
                });
            });
        }
    }
});
