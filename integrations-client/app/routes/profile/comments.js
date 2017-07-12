import Ember from 'ember';
import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';

export default Ember.Route.extend(AuthenticatedRouteMixin,{
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    queryParams: {
        skillset_id: {
            refreshModel: true
        },
        role_id: {
            refreshModel: true
        },
        page: {
            refreshModel: true
        },
    },
    actions: {
        refresh(){
            this.refresh();
        }
    },
    model: function(params) { 
        params["id"] = this.paramsFor("profile").id;
        this.store.adapterFor('aggregate-comment').set('namespace', 'users/'+params.id);
        var comments = this.get('store').query('aggregate-comment', params);
        this.store.adapterFor('aggregate-comment').set('namespace', '');
        return Ember.RSVP.hash({
            teams: this.store.findAll('team'),
            skillsets: this.modelFor("profile").skillsets,
            roles: this.modelFor("profile").roles,
            user: this.modelFor("profile").user,
            states: this.modelFor("profile").states,
            params: params,
            comments: comments,
            me: false 
        });
    },
    renderTemplate() {
        this.render('me.comments');
    }
});
