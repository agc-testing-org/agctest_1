import Ember from 'ember';

export default Ember.Route.extend({
    store: Ember.inject.service(),
    model: function(params) {     
        return Ember.RSVP.hash({
            states: this.store.findAll('state'),
            repositories: this.store.findAll('repository'),
            comments: this.store.queryRecord('aggregate-comment', {
                user_id: params.username
            }),        
            votes: this.store.queryRecord('aggregate-vote', {
                user_id: params.username
            }),
            contributors: this.store.queryRecord('aggregate-contributor', {
                user_id: params.username
            })
        });
    }
});
