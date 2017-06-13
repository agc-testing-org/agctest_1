import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    actions: {
        invite(teamId){
            var _this = this;
            var email = this.get('email');
            var default_seat_id = this.get('default_seat_id');
            if(email && email.length > 4){
                var invitation = this.get('store').createRecord('user-team', {
                    team_id: teamId,
                    user_email: email,
                    seat_id: default_seat_id
                });
                invitation.save().then(function(){
                    _this.sendAction("refresh");
                });
            }
        },
        selectSeat(seatId){
            this.set("default_seat_id",seatId);
        }

    }

});
