import Ember from 'ember';
import BaseRoute from 'integrations-client/routes/base';

export default BaseRoute.extend({
    actions: {
        refresh(){
            this.refresh();
        }
    },
    store: Ember.inject.service(),
    model: function(params) {
        this.store.adapterFor('clear').set('namespace', ''); //clear namespaces
        var memberSeat = this.store.peekAll("seat").findBy("name","member");
        var authenticated = this.get('session.isAuthenticated');
        var teams = [];
        if(authenticated){
            teams = this.store.query('team',{
                seat_id: memberSeat.get("id")
            });
        }
        return Ember.RSVP.hash({
            projects: this.store.findAll('project'),
            teams: teams,
        });
    },
});
