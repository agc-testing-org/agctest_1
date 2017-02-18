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
            var _this = this;
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

                    _this.set("showComment",false);
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
            }).save().then(function(payload) {      
                if(payload.get("created")){
                    console.log("YES");
                    store.peekRecord('contributor',contributor_id).get('votes').addObject(payload);
                }else{
                    console.log("NO");
                    store.peekRecord('vote',payload.get("id")).deleteRecord();
                    //store.peekRecord('contributor',contributor_id).get('votes').removeObject(payload);
                }
                //   console.log("refreshing");                    
                // _this.sendAction("refresh");                                  
            });                                                                             
        },
        judge(contributor_id,sprint_state_id,project_id){
            var store = this.get('store');
            store.adapterFor('winner').set('namespace', 'contributors/' + contributor_id );

            var feedback = store.createRecord('winner', {
                contributor_id: contributor_id,
                sprint_state_id: sprint_state_id,
                project_id: project_id
            }).save().then(function(payload) {
                store.peekRecord('sprint-state',sprint_state_id).set('winner',payload.get("id"));
                //   console.log("refreshing");                    
                // _this.sendAction("refresh");                                  
            });
        },
        merge(contributor_id,sprint_state_id,project_id){
            var store = this.get('store');
            store.adapterFor('merge').set('namespace', 'contributors/' + contributor_id );

            var feedback = store.createRecord('merge', {
                contributor_id: contributor_id,
                sprint_state_id: sprint_state_id,
                project_id: project_id
            }).save().then(function(payload) {
                store.peekRecord('sprint-state',sprint_state_id).set('merge',payload.get("merged"));
                //   console.log("refreshing");                    
                // _this.sendAction("refresh");                                  
            });
        }
    }
});
