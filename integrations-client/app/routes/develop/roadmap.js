import Ember from 'ember';
import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';

export default Ember.Route.extend(AuthenticatedRouteMixin,{
    actions: {
        refresh(){
            this.refresh();
        }
    },
    store: Ember.inject.service(),
    model: function(params) {
 
        var memberSeat = this.store.peekAll("seat").findBy("name","member");
        return Ember.RSVP.hash({
            projects: this.store.findAll('project'),
            teams: this.store.query('team',{
                seat_id: memberSeat.get("id")
            }),
            jobs: this.store.query('job',{},{reload: true}),
        });
    },
});
