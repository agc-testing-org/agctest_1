import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    filteredRoles: Ember.computed.filterBy("roles","active",true),
    filteredSkillsets: Ember.computed.filterBy("skillsets","active",true),
    didRender() {
        this._super(...arguments);
        this.$('[data-toggle="tooltip"]').tooltip('show');
    },
    actions: {
        refresh(){
            this.sendAction("refresh");
        }
    }
});
