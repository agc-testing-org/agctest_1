import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    activeRoles: Ember.computed.filterBy("roles","active",true),
    recruiter: Ember.computed.filterBy("activeRoles","name","recruiting"),
    manager: Ember.computed.filterBy("activeRoles","name","management"),
    sessionAccount: Ember.inject.service('session-account'),
    actions: {
        refresh(){
            this.sendAction("refresh");
        }
    }
});
