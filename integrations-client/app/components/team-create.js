import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    errorMessage: null,
    routes: Ember.inject.service('route-injection'),
    planId: null,
    actions: {
        setType(planId){
            this.set("planId",planId);
        },
        create(){
            var _this = this;
            var name = this.get('name');
            var plan = this.get('planId');
            if(name && (name.length > 1)&&(name.length < 31)){
                if(plan){
                    var team = this.get('store').createRecord('team', {
                        name: name,
                        plan_id: plan
                    });
                    team.save().then(function(payload){
                        _this.get("routes").redirectWithId("team.select",payload.id);
                    }, function(xhr, status, error) {
                        var response = xhr.errors[0].detail;
                        _this.set("errorMessage",response);
                    });
                }
                else {
                    this.set("errorMessage","Please select a team type");
                }
            }
            else {
                this.set("errorMessage","Please enter a more descriptive team name");
            }
        }
    }

});
