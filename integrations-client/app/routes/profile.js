import Ember from 'ember';

export default Ember.Route.extend({
    store: Ember.inject.service(),
    model: function(params) {
        //var post_id = this.modelFor('post.show').get('id');
     
        return Ember.RSVP.hash({
            states: this.store.findAll('state'),
            repositories: this.store.findAll('repository'),
            //            sprints: this.store.findAll('sprint')
            comments_user_id: this.store.queryRecord('aggregate-comment', {
                user_id: params.username
            }),        
            comments_contributor_id:this.store.queryRecord('aggregate-comment', {
                contributor_id: params.username
            }),  
            votes_user_id: this.store.queryRecord('aggregate-vote', {
                user_id: params.username
            }),
            votes_contributor_id:this.store.queryRecord('aggregate-vote', {
                contributor_id: params.username
            }),
            contributors_user_id: this.store.queryRecord('aggregate-contributor', {
                user_id: params.username
            }),
            contributors_contributor_id:this.store.queryRecord('aggregate-contributor', {
                contributor_id: params.username,
                user_id: params.username 
            }),
        });
    }
});
