import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    showComment: false,
    actions: {
        displayComment(shouldDisplay){
            this.set("showComment",shouldDisplay);
        },
        comment(contributor_id,sprint_state_id){
            console.log(":::"+sprint_state_id);
            var comment = this.get("comment");
            if(comment.length < 500){
                var store = this.get('store');
                store.adapterFor('comment').set('namespace', 'contributors/' + contributor_id );

                var feedback = store.createRecord('comment', {
                    sprint_state_id: sprint_state_id,
                    text: comment
                }).save().then(function() {
                 //   console.log("refreshing");
                   // _this.sendAction("refresh");
                });

            }
            else{
                //comment too long
            }
        },
        vote(contributor_id,sprint_state_id){
            var store = this.get('store');
            store.adapterFor('vote').set('namespace', 'contributors/' + contributor_id );

            var feedback = store.createRecord('vote', {
                sprint_state_id: sprint_state_id
            }).save().then(function() {                                         
                //   console.log("refreshing");                    
                // _this.sendAction("refresh");                                  
            });                                                                             
        }
    }
});
