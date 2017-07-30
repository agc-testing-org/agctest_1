import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    actions: {
        readTeamConnectionRequests(id, read, teamId){

            var store = this.get('store');

            store.adapterFor('connection').set('namespace', 'teams/'+teamId);

            var requestRead = store.findRecord('connection', id).then(function (connection) {
                connection.set('read', read);
                connection.save().then(function () {
                     store.adapterFor('connection').set('namespace', '');
                });
            });
        }
    }
});