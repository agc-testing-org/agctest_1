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
        this.store.adapterFor('aggregate-contributor').set('namespace', 'users/me');
        var contributors = this.get('store').query('aggregate-contributor', params);
        this.store.adapterFor('aggregate-contributor').set('namespace', '');
        return Ember.RSVP.hash({
            skillsets: this.modelFor("me").skillsets,
            roles: this.modelFor("me").roles,
            user: this.modelFor("me").user,
            states: this.modelFor("me").states,
            params: params,
            contributors: contributors,
            me: true
        });
    },
});
