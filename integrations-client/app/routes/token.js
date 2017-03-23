import Ember from 'ember';
import UnAuthenticatedRouteMixin from 'ember-simple-auth/mixins/unauthenticated-route-mixin';

export default Ember.Route.extend(UnAuthenticatedRouteMixin,{
    activate () {
        Ember.$('body').addClass('body-dark');
    },
    deactivate () {
        Ember.$('body').removeClass('body-dark');
        Ember.$('#register-modal').modal('hide');
    },
    model: function(params) {
        return params.id;
    },
});
