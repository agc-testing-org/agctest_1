import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    comment_offensive: function() {
        if(this.get('sprint_state.votes')){
            return this.get('sprint_state.votes').filterBy('comment_id',parseInt(this.get("comment_id"))).filterBy('user_id', (this.get("user_id"))).filterBy("flag", true);
        }
        else{
            return [];
        }
    }.property('sprint_state.votes.@each'),
    
    actions: {
        commentOffensive(contributor_id,sprint_state_id,comment_id,flag){
            this.set("errorMessage", "");
            var _this = this;
            var store = this.get('store');
            store.adapterFor('vote').set('namespace', 'sprints');
            var feedback = store.createRecord('vote', {
                contributor_id: contributor_id,
                sprint_state_id: sprint_state_id,
                comment_id: comment_id,
                flag: flag
            }).save().then(function(payload) {      
                if(payload.get("created")){
                    if(payload.get("previous")){
                        var previous_contributor = store.peekRecord('sprint_state',payload.get("previous")).get('votes');
                        var previous_vote = previous_contributor.findBy("id",payload.get("id"));
                        previous_contributor.removeObject(previous_vote);
                    }
                    store.peekRecord('sprint_state',sprint_state_id).get('votes').addObject(payload);
                }
            }, function(xhr, status, error) {
                if(error){ // handle non-api error
                    var response = xhr.errors[0].detail;
                    _this.set("errorMessage",response);
                }
            });
        },
    }
});