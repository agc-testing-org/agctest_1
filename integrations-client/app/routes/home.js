import Ember from 'ember';
import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';

export default Ember.Route.extend(AuthenticatedRouteMixin,{
    store: Ember.inject.service(),
    model: function(params) {

        //        this.store.adapterFor('sprint').set('namespace', 'projects/' + 1 );
        //        console.log(this.get('session-account'));

        return Ember.RSVP.hash({
            states: this.store.findAll('state'),
            projects: this.store.findAll('project'),
            repositories: this.store.findAll('repository'),
            comments: this.store.queryRecord('aggregate-comment', {
             
            }),
            votes: this.store.queryRecord('aggregate-vote', {
            
            }),
            contributors: this.store.queryRecord('aggregate-contributor', {
           
            })
        });
    }
});
