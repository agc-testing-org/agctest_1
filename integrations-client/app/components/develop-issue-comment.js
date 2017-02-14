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
                    contributor_id: contributor_id,
                    sprint_state_id: sprint_state_id,
                    text: comment
                }).save().then(function(payload) {
                    store.peekRecord('contributor',contributor_id).get('comments').addObject(payload);
  //                  console.log(payload);
                 //   console.log("refreshing");
                   // _this.sendAction("refresh");
                 //   store.push({
                   //       data: {
                     //       id
                      //    }
                   // });
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
                contributor_id: contributor_id,
                sprint_state_id: sprint_state_id
            }).save().then(function() {                                        
                //   console.log("refreshing");                    
                // _this.sendAction("refresh");                                  
            });                                                                             
        }
    }
});
