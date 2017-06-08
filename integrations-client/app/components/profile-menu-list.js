import Ember from 'ember';

const { inject: { service }, Component } = Ember;

export default Component.extend({
    session: service('session'),
    sessionAccount: Ember.inject.service('session-account'),
    didRender() {
        this._super(...arguments);
    },
    actions: {

    }
});
