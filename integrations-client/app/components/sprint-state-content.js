import Ember from 'ember';

const { inject: { service }, Component } = Ember;

export default Component.extend({
    session: service('session'),
    sessionAccount: Ember.inject.service('session-account'),
    store: Ember.inject.service(),
    didRender() {
        this._super(...arguments);
    },
    actions: {
        join(project_id, sprint_state_id){
            var _this = this;
            var store = this.get('store');
            var project = store.createRecord('contributor', {
                sprint_state_id: sprint_state_id
            }).save().then(function() {
                _this.sendAction("refresh");
            });
        },
        refresh(){
            this.sendAction("refresh");
        }

    }
});
