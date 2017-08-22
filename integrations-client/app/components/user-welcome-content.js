import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    activeRoles: Ember.computed.filterBy("roles","active",true),
    recruiter: Ember.computed.filterBy("activeRoles","name","recruiting"),
    manager: Ember.computed.filterBy("activeRoles","name","management"),
    managerPlan: Ember.computed.filterBy("plans","name","manager"),
    managerTeams: function() {
        return this.get('teams').filterBy('plan_id', parseInt(this.get("managerPlan")[0].id));
    }.property('teams.@each.id'),
    init() {
        this._super(...arguments);
    },
});
