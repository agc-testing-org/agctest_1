import Ember from 'ember';

const { inject: { service }, Component } = Ember;

export default Component.extend({
    session: service('session'),
    didRender() {
        this._super(...arguments);
    },
    actions: {

    }
});
