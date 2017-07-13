import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    sessionAccount: Ember.inject.service('session-account'),
    store: Ember.inject.service(),
    actions: {
        submit(project_id, contributor_id){
            var _this = this;
            var store = this.get('store');

            var contributorUpdate = store.findRecord('contributor',contributor_id).then(function(contributor) {
                contributor.save().then(function() {
                    _this.sendAction("refresh");
                });
            });
        }
    }
});
