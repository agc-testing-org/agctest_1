import Ember from 'ember';

export default Ember.Route.extend({
    store: Ember.inject.service(),
    model: function(params) {
        //var post_id = this.modelFor('post.show').get('id');
        //        this.store.adapterFor('sprint').set('namespace', 'projects/' + 1 );

        return Ember.RSVP.hash({
            repositories: this.store.findAll('repository'),
            //            sprints: this.store.findAll('sprint')
            comments_user_id: this.store.query('comment', {
                user_id: params.username
            }),        
            comments_contributor_id:this.store.query('comment', {
                contributor_id: params.username
            }),   
            states: this.store.findAll('state'),
        });
    }
});
