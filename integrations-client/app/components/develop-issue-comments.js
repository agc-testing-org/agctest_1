import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    count: 3,
    showingAll: false,
    sortedComments: Ember.computed.sort('comments', 'sortDefinition'),
    sortDefinition: ['created_at:desc'],
    actions: {
        showAll(yesNo){
            var number = 3;
            if(yesNo){
                number = this.get("comments").toArray().length;
            }
            this.set("count",number);
            this.set("showingAll",yesNo);
        },

        vote(contributor_id,sprint_state_id,comment_id){
            console.log(contributor_id)
            console.log(comment_id)
            console.log(sprint_state_id)
            this.set("errorMessage", "");
            var _this = this;
            var store = this.get('store');
            store.adapterFor('vote').set('namespace', 'contributors/' + contributor_id );
            var feedback = store.createRecord('vote', {
                contributor_id: contributor_id,
                sprint_state_id: sprint_state_id,
                comment_id: comment_id
            }).save().then(function(payload) {      
                if(payload.get("created")){
                    if(payload.get("previous")){
                        var previous_contributor = store.peekRecord('contributor',payload.get("previous")).get('votes');
                        var previous_vote = previous_contributor.findBy("id",payload.get("id"));
                        previous_contributor.removeObject(previous_vote);
                    }
                    store.peekRecord('contributor',contributor_id).get('votes').addObject(payload);
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
