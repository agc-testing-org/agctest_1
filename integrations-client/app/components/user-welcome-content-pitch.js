import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    managerTeams: function() {
        return this.get('teams').filterBy('plan_id', parseInt(this.get("managerPlan")[0].id));
    }.property('teams.@each.id'),
    init() {
        this._super(...arguments);
    },
});
