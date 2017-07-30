import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    actions: {
        confirmTeamConnectionRequests(id, confirmed, teamId){

            var store = this.get('store');

            store.adapterFor('connection').set('namespace', 'teams/'+teamId);

            var requestConfirm = store.findRecord('connection', id).then(function (connection) {
                connection.set('confirmed', confirmed);
                connection.save().then(function () {
                    store.adapterFor('connection').set('namespace', '');
                });
            });
        }
    }
});