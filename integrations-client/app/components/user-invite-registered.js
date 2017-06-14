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

            store.adapterFor('token').set('namespace', 'user-teams' );
            var token = store.createRecord('token', {
                token: inviteId 
            }).save();
            
            token.then(function(payload) {
                store.adapterFor('token').set('namespace', '');
                _this.get("routes").redirectWithId("team.select",payload.get("team_id"));
            });
        },
    }
});
