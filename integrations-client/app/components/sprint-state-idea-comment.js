import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    errorMessage: null,
    votes_count: Ember.computed.filterBy('sprint_state.votes','comment_id', null),

    actions: {
        comment(contributor_id,sprint_state_id){
            this.set("errorMessage", "");
            var _this = this;
            var comment = this.get("comment");
            if(comment && (comment.length > 1)){
                if(comment.length < 5001){ 
                    var store = this.get('store');
                    store.adapterFor('comment').set('namespace', 'sprints');

                    var feedback = store.createRecord('comment', {
                        contributor_id: contributor_id,
                        sprint_state_id: sprint_state_id,
                        text: comment
                    }).save().then(function(payload) {
                        store.peekRecord('sprint_state',sprint_state_id).get('comments').addObject(payload);
                        _this.set("comment",null);
                    }, function(xhr, status, error) {
                        var response = xhr.errors[0].detail;
                        _this.set("errorMessage",response);
                    });
                }
                else{
                    this.set('errorMessage', "Comments must be less than 5000 characters"); 
                }
            }
            else {
                this.set('errorMessage', "Please enter a more detailed comment");
            }
        },
        vote(contributor_id,sprint_state_id){
            this.set("errorMessage", "");
            var _this = this;
            var store = this.get('store');
            var sprint_state_votes = store.peekAll('vote').filterBy("sprint_state_id",parseInt(sprint_state_id));
            var owned_vote = null;
            var owned_vote_id = null;
            if(sprint_state_votes){
                sprint_state_votes = sprint_state_votes.filterBy("comment_id",null);
                owned_vote = sprint_state_votes.findBy("user_id",this.get("sessionAccount.account.id"));
                if(owned_vote){
                    owned_vote_id = owned_vote.get("id");
                    store.unloadRecord(owned_vote);
            //        store.peekAll('vote').removeObject(owned_vote);
            //        store._removeFromIdMap(owned_vote._internalModel);
                }
            }
            store.adapterFor('vote').set('namespace', 'sprints');
            var feedback = store.createRecord('vote', {
                id: owned_vote_id,
                contributor_id: contributor_id,
                sprint_state_id: sprint_state_id
            }).save().then(function(payload) {    
                if(payload.get("created")){
                    if(payload.get("previous")){
                        var previous_contributor = store.peekRecord('contributor',payload.get("previous")).get('votes');
                        var previous_vote = previous_contributor.findBy("id",payload.get("id"));
                        previous_contributor.removeObject(previous_vote);
                    }
                }
                store.peekRecord('sprint_state',sprint_state_id).get('votes').addObject(payload);
            }, function(xhr, status, error) {
                if(error){ // handle non-api error
                    var response = xhr.errors[0].detail;
                    _this.set("errorMessage",response);
                }
            });
        }
    }
});
