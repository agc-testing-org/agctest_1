import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),

    actions: {
        commentOffensive(contributor_id,sprint_state_id,comment_id,flag){
            this.set("errorMessage", "");
            var _this = this;
            var store = this.get('store');
            store.adapterFor('vote').set('namespace', 'contributors/' + contributor_id );
            var feedback = store.createRecord('vote', {
                contributor_id: contributor_id,
                sprint_state_id: sprint_state_id,
                comment_id: comment_id,
                flag: flag
            }).save().then(function(xhr, status, error) {
                if(error){ // handle non-api error
                    var response = xhr.errors[0].detail;
                    _this.set("errorMessage",response);
                }
            });
        },
    }
});