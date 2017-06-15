import Ember from 'ember';

const { inject: { service }, Component } = Ember;

export default Component.extend({
    session: service('session'),
    sessionAccount: Ember.inject.service('session-account'),
    store: Ember.inject.service(),
    active: Ember.computed.filterBy('items','active', true),
    didRender() {
        this._super(...arguments);
    },
    actions: {

    }
});
