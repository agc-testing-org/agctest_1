import Ember from 'ember';

const { inject: { service }, Component } = Ember;

export default Component.extend({
    session: service('session'),
    store: Ember.inject.service(),
    routes: Ember.inject.service('route-injection'),
    didRender() {
        this._super(...arguments);
        this.$('#register-modal').modal('show');
    },
    actions: {
        accept(inviteId) {
            var _this = this;
            var store = this.get('store');
            store.adapterFor('team').set('namespace', 'account' );
            store.createRecord('team', {
                token: inviteId 
            }).save().then(function(payload) {
                _this.get("routes").redirectWithId("team",payload.id);
            });
        },
    }
});
