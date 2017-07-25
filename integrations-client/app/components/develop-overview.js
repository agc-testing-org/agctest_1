import Ember from 'ember';
import config from 'integrations-client/config/environment';

const { inject: { service }, Component } = Ember;

export default Component.extend({
    session: service('session'),
    sessionAccount: Ember.inject.service('session-account'),
    org: config.org,
    didRender() {
        this._super(...arguments);
    },
    actions: {
    }
});
