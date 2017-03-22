import Ember from 'ember';
import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';

export default Ember.Route.extend(AuthenticatedRouteMixin,{
    store: Ember.inject.service(),
    model: function(params) {
        //var post_id = this.modelFor('post.show').get('id');
        //        this.store.adapterFor('sprint').set('namespace', 'projects/' + 1 );

        return Ember.RSVP.hash({
            repositories: this.store.findAll('repository'),
            //            sprints: this.store.findAll('sprint')


        });
    }
});
