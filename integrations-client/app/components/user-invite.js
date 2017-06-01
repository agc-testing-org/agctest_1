import Ember from 'ember';

const { inject: { service }, Component } = Ember;

export default Component.extend({
    session: service('session'),
    store: Ember.inject.service(),
    didRender() {
        this._super(...arguments);
        this.$('#register-modal').modal('show');
    },
    actions: {
        accept(inviteId) {
            var store = this.get('store');
            store.adapterFor('team').set('namespace', 'account' );
            store.createRecord('team', {
                id: inviteId 
            }).save().then(function() {
                alert("here"); 
            });
        },
    }
});
