import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    routes: Ember.inject.service('route-injection'),
    sessionAccount: Ember.inject.service('session-account'),
    project: null,
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
                _this.set("project",response);
            });
        },
        refresh(){
            this.sendAction("refresh");
        }
    }

});
