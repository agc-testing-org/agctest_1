import Ember from 'ember';
import config from 'integrations-client/config/environment';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    mergedStates: Ember.computed.filterBy('sprint.sprint_states','merged', true),
    org: config.org,
    actions: {
        refresh(){
            this.sendAction("refresh");
        }
    }
});
