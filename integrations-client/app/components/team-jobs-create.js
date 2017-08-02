import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    routes: Ember.inject.service('route-injection'),
    sessionAccount: Ember.inject.service('session-account'),
    errorMessage: null, 
    init() { 
        this._super(...arguments);   
    },
    actions: {
        create(team_id){
            var title = this.get("title");
            var link = this.get("link");
            var _this = this;
            if(title && title.length > 4){
                if(link){
                    var job = this.get('store').createRecord('job', {
                        team_id: team_id,
                        title: title, 
                        link: link,
                    }).save().then(function(response){
                        _this.set("errorMessage",null); 
                        _this.sendAction("refresh");
                    });
                }
                else {
                    _this.set("errorMessage","A link to the position is required");
                }
            }
            else{
                _this.set("errorMessage","Title must be 5-100 characters");
            }
        },
    }

});
