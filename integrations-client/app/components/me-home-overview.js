import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    didRender() {
        this._super(...arguments);
    },
    actions: {
        refresh(){
            this.sendAction("refresh");
        }
    }
});
