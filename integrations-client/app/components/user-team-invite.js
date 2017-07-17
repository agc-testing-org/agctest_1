import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    errorMessage: null,
    selectedSeat: null,
    actions: {
        invite(teamId){
            var _this = this;
            var email = this.get('email');
             _this.set("errorMessage",null);   
            var selectedSeat = this.get("selectedSeat");
            if(!selectedSeat){
                selectedSeat = this.get('default_seat.id');
            }
            if(email && email.length > 4){
                var invitation = this.get('store').createRecord('user-team', {
                    team_id: teamId,
                    user_email: email,
                    seat_id: selectedSeat 
                });
                invitation.save().then(function(){
                    _this.sendAction("refresh");
                }, function(xhr, status, error) {
                    var response = xhr.errors[0].detail;
                    _this.set("errorMessage",response);
                });
            }
        },
        selectSeat(seatId){
            this.set("selectedSeat",seatId);
        }

    }

});
