import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    actions: {
        invite(teamId){
            var _this = this;
            var email = this.get('email');
            if(email && email.length > 4){
                var project = this.get('store').createRecord('user-team', {
                    team_id: teamId,
                    user_email: email
                });
                project.save().then(function(){
                    _this.sendAction("refresh");
                });
            }
        }
    }

});
