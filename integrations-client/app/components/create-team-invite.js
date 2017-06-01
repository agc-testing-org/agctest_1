import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    actions: {
        invite(teamId){
            var email = this.get('email');
            if(email && email.length > 4){
                var project = this.get('store').createRecord('team-invite', {
                    id: teamId,
                    email: email
                });
                project.save();
            }
        }
    }

});
