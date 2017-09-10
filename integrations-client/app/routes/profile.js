import Ember from 'ember';
import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';

export default Ember.Route.extend(AuthenticatedRouteMixin,{
    store: Ember.inject.service(),

    actions: {
        refresh(){
            this.refresh();
        }
    },

    model: function(params) {     

        var store = this.get('store');
        store.adapterFor('clear').set('namespace', ''); //clear namespaces

        var states = this.store.findAll('state');
        var user = this.store.find('user',params.id);
        this.store.adapterFor('skillset').set('namespace', 'users/'+params.id);
        var skillsets = this.store.findAll('skillset');
        var roles = this.store.findAll('role');
        var request = this.store.queryRecord('request',{});
        this.store.adapterFor('skillset').set('namespace', '');

        return Ember.RSVP.hash({
            roles: roles,
            skillsets: skillsets,
            user: user,
            states: states,
            params: params,
            me: false,
            request: request
        });
    },
    renderTemplate(controller,model) {
        this.render('me', {
            into: 'application',
            controller: controller, 
            model: model
        });
    },
    afterModel(model,transition) {
        //        this.transitionTo('profile.overview',model.user.id);
    }
});
