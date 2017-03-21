import Ember from 'ember';

export default Ember.Route.extend({
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
