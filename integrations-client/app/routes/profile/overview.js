import Ember from 'ember';
import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';

export default Ember.Route.extend(AuthenticatedRouteMixin,{
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    actions: {
        // let parent route handle refresh to avoid reloading everything
        //        refresh(){
        //            this.refresh();
        //        }
    },
    model: function(params) { 

        params["id"] = this.paramsFor("profile").id;
        this.store.adapterFor('aggregate-comment').set('namespace', 'users/'+params.id);
        var comments = this.get('store').query('aggregate-comment', params);
        var votes = this.get('store').query('aggregate-vote', params);
        var contributors = this.get('store').query('aggregate-contributor', params);
        var comments_received = this.get('store').query('aggregate-comments-received', params);
        var votes_received = this.get('store').query('aggregate-votes-received', params);
        var contributors_received = this.get('store').query('aggregate-contributors-received', params);
        this.store.adapterFor('aggregate-comment').set('namespace', ''); 

        return Ember.RSVP.hash({
            skillsets: this.modelFor("profile").skillsets,
            roles: this.modelFor("profile").roles,
            user: this.modelFor("profile").user,
            states: this.modelFor("profile").states,
            request: this.modelFor("profile").request,
            params: params,
            comments: comments,
            votes: votes,
            contributors: contributors,
            comments_received: comments_received,
            votes_received: votes_received,
            contributors_received: contributors_received,
            me: false 
        });
    },
    renderTemplate(controller,model) {
        this.render('me.overview', {
            controller: controller,
            model: model
        });

    }
});
