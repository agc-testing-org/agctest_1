import Ember from 'ember';
import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';

export default Ember.Route.extend(AuthenticatedRouteMixin,{
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    model: function(params) {
        //var post_id = this.modelFor('post.show').get('id');
        //        this.store.adapterFor('sprint').set('namespace', 'projects/' + 1 );
//        console.log(this.get('session-account'));
        var username = this.get('sessionAccount').account.id;

        return Ember.RSVP.hash({
            states: this.store.findAll('state'),
            repositories: this.store.findAll('repository'),
            comments: this.store.queryRecord('aggregate-comment', {
                user_id: username
            }),
            votes: this.store.queryRecord('aggregate-vote', {
                user_id: username
            }),
            contributors: this.store.queryRecord('aggregate-contributor', {
                user_id: username
            })
        });
    }
});
