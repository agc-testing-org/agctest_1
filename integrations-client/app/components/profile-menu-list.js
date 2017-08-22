import Ember from 'ember';

const { inject: { service }, Component } = Ember;

export default Component.extend({
    session: service('session'),
    sessionAccount: Ember.inject.service('session-account'),
    showTeams: false,
    activeRoles: Ember.computed.filterBy("roles","active",true),
    recruiter: Ember.computed.filterBy("activeRoles","name","recruiting"),
    manager: Ember.computed.filterBy("activeRoles","name","management"),
    didRender() {
        this._super(...arguments);
    },
    actions: {
        displayTeams(){
            if(this.get("showTeams")){
                this.set("showTeams",false);
            }
            else {
                this.set("showTeams",true);
            }
        }
    }
});
