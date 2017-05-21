import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    sessionAccount: Ember.inject.service('session-account'),
    routes: Ember.inject.service('route-injection'),
    store: Ember.inject.service(),
    actions: {
        transition(id,transition){
            var _this = this;
            var store = this.get('store');
            store.createRecord('sprint-state', {
                sprint: id,
                state: transition
            }).save().then(function(payload) {
                 _this.sendAction("refresh");
            });
        }
    }
});
