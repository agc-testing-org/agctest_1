import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    errorMessage: null,
    routes: Ember.inject.service('route-injection'),
    planId: null,
    activeRoles: Ember.computed.filterBy("roles","active",true),
    recruiter: Ember.computed.filterBy("activeRoles","name","recruiting"),
    manager: Ember.computed.filterBy("activeRoles","name","management"),
    init() {
        this._super(...arguments);
        var manager = this.get("manager");
        var recruiter = this.get("recruiter");
        if(this.get("plans")){
            if(manager.length > 0){
                this.send("setType",this.get("plans").findBy("name","manager").id);
            }
            else if(recruiter.length > 0){
                this.send("setType",this.get("plans").findBy("name","recruiter").id);
            }
        }
    },
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
                        if(plan === _this.get("plans").findBy("name","manager").id){
                            _this.get("routes").redirectWithId("team.select.jobs",payload.id);
                        }
                        else {
                            _this.get("routes").redirectWithId("team.select.talent",payload.id);
                        }
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
