import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    errorMessage: null,
    actions: {
        createTeam(){
            var name = this.get("name");
            if(name.length > 2){
                var project = this.get('store').createRecord('team', {
                    name: name 
                }).save();
            }
            else {
                this.set("errorMessage","Name must be 3 or more characters");
            }
        }
    }
});
