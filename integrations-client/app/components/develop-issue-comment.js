import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    errorMessage: null,
    votes_count: Ember.computed.filterBy('contributor.votes','comment_id', null),

    actions: {
        comment(contributor_id,sprint_state_id){
            this.set("errorMessage", "");
            var _this = this;
            var comment = this.get("comment");
            if(comment && (comment.length > 1)){
                if(comment.length < 5001){ 
                    var store = this.get('store');
                    store.adapterFor('comment').set('namespace', 'contributors/' + contributor_id );

                    var feedback = store.createRecord('comment', {
                        contributor_id: contributor_id,
                        sprint_state_id: sprint_state_id,
                        text: comment
                    }).save().then(function(payload) {
                        store.peekRecord('contributor',contributor_id).get('comments').addObject(payload);
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
            store.adapterFor('vote').set('namespace', 'contributors/' + contributor_id );
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
                store.peekRecord('contributor',contributor_id).get('votes').addObject(payload);
            }, function(xhr, status, error) {
                if(error){ // handle non-api error
                    var response = xhr.errors[0].detail;
                    _this.set("errorMessage",response);
                }
            });
        },
        judge(contributor_id,sprint_state_id,project_id){
            this.set("errorMessage", "");
            var store = this.get('store');
            store.adapterFor('winner').set('namespace', 'contributors/' + contributor_id );
            var _this = this;
            var feedback = store.createRecord('winner', {
                contributor_id: contributor_id,
                sprint_state_id: sprint_state_id,
                project_id: project_id
            }).save().then(function(payload) {
                store.peekRecord('sprint-state',sprint_state_id).set('winner',payload.get("id"));
                _this.sendAction("refresh");                                  
            }, function(xhr, status, error) {
                if(error){
                    var response = xhr.errors[0].detail;
                    _this.set("errorMessage",response);
                }
            });
        },
        merge(contributor_id,sprint_state_id,project_id){
            this.set("errorMessage", "");
            var store = this.get('store');
            store.adapterFor('merge').set('namespace', 'contributors/' + contributor_id );
            var _this = this;
            var feedback = store.createRecord('merge', {
                contributor_id: contributor_id,
                sprint_state_id: sprint_state_id,
                project_id: project_id
            }).save().then(function(payload) {
                store.peekRecord('sprint-state',sprint_state_id).set('merge',payload.get("merged"));
                _this.sendAction("refresh");                                  
            }, function(xhr, status, error) {
                var response = xhr.errors[0].detail;
                _this.set("errorMessage",response);
            });
        }
    }
});
