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
        this.store.adapterFor('aggregate-votes-received').set('namespace', 'users/'+params.id);
        var votes_received = this.get('store').query('aggregate-votes-received', params);
        this.store.adapterFor('aggregate-votes-received').set('namespace', '');
        return Ember.RSVP.hash({
            teams: this.store.findAll('team'),
            skillsets: this.modelFor("profile").skillsets,
            roles: this.modelFor("profile").roles,
            user: this.modelFor("profile").user,
            states: this.modelFor("profile").states,
            params: params,
            votes_received: votes_received,
            me: false 
        });
    },
    renderTemplate() {
        this.render('me.votes_received');
    }
});
