import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    displayCreate: null,
    errorMessage: null,
    sortedEvents: Ember.computed.sort('model.events', 'sortDefinition'),
    sortDefinition: ['created_at:desc'],
    init() {
        this._super(...arguments);
    },
    actions: {

    }

});
