import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    sessionAccount: Ember.inject.service('session-account'),
    routes: Ember.inject.service('route-injection'),
    store: Ember.inject.service(''),
    errorMessage: null,
    selectedSeatName: function() {
        return this.get("default_seat_name");
    }.property('team'),
    selectedSeatId: function() {
        return this.get("default_seat_id");
    }.property('team'),
    selectedJob: function() { 
        return this.get("job");
    }.property('job'),
    selectedTeam: function() {
        return this.get("team");
    }.property('team'),
    actions: {
        invite(){
            var _this = this;

            _this.set("errorMessage",null);
            _this.set("successMessage",null);
            var email = this.get('email');

            var selectedSeatId = this.get("selectedSeatId");
            var selectedJob = this.get("selectedJob");
            var selectedJobId = null;
            if(selectedJob){
                selectedJobId = selectedJob.id;
            }
            var selectedTeam = this.get("selectedTeam");
            var profileId = this.get("profile_id");

            if(email && email.length > 4){
                if(selectedTeam){
                    var invitation = this.get('store').createRecord('user-team', {
                        team_id: selectedTeam.id,
                        user_email: email,
                        seat_id: selectedSeatId,
                        job_id: selectedJobId,
                        profile_id: profileId
                    });
                    invitation.save().then(function(){
                        _this.set("email",null);
                        _this.set("successMessage",true);  

                        Ember.run.later((function() {
                            _this.set("successMessage",null); 
                            _this.sendAction("refresh");
                        }), 3000);
                    }, function(xhr, status, error) {
                        var response = xhr.errors[0].detail;
                        _this.set("errorMessage",response);
                    });
                }
                else {
                    _this.set("errorMessage","select a team to manage the candidate");
                }
            }
            else{
                _this.set("errorMessage","please enter a valid email address");
            }
        },
        selectTeam(team){
            this.set("selectedTeam",team);
            this.set("selectedSeatId",team.get("default_seat_id"));
        },
        selectSeat(seat){
            this.set("selectedSeatId",seat.get("id"));
            this.set("selectedSeatName",seat.get("name"));
        },
        selectJob(job){
            this.set("selectedJob",job);
        }
    }

});
