import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    sessionAccount: Ember.inject.service('session-account'),
    routes: Ember.inject.service('route-injection'),
    store: Ember.inject.service(''),
    errorMessage: null,
    selectedSeat: null,
    actions: {
        invite(teamId, profileId){
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
                    seat_id: selectedSeat,
                    profile_id: profileId
                });
                invitation.save().then(function(){
                    _this.set("email","");
                    _this.sendAction("refresh");
                    if(profileId){
                        _this.get("routes").redirectWithId("team.select.shares",teamId);
                    }
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
