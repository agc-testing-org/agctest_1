import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    routes: Ember.inject.service('route-injection'),
    sessionAccount: Ember.inject.service('session-account'),
    init() { 
        this._super(...arguments);   
    },
    actions: {
        createProject(org,name){
            var _this = this;
            var project = this.get('store').createRecord('project', {
                org: org,
                name: name
            }).save().then(function(response){
              //  _this.get("routes").redirectWithId("develop.project",response);
              _this.get("routes").redirect("me");
            });
        },
        refresh(){
            this.sendAction("refresh");
        }
    }

});
