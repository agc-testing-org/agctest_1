import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    routes: Ember.inject.service('route-injection'),
    sessionAccount: Ember.inject.service('session-account'),
    errorMessage: null,
    role_id: null,
    init() { 
        this._super(...arguments);   
    },
    actions: {
        role(role){
            this.set("role_id",role);
        },
        create(team_id){
            var title = this.get("title");
            var link = this.get("link");
            var zip = this.get("zip");
            var role_id = this.get("role_id");
            var _this = this;
            if(title && title.length > 4){
                if(link){
                    if(link.includes("http")){
                        if(role_id){
                            if(zip && zip.length > 4){
                                var job = this.get('store').createRecord('job', {
                                    team_id: team_id,
                                    title: title,
                                    role_id: role_id,
                                    link: link,
                                    zip: zip
                                }).save().then(function(response){
                                    _this.set("errorMessage",null); 
                                    _this.set("title",null);
                                    _this.set("link",null);
                                    _this.sendAction("refresh");
                                });
                            }
                            else {
                                _this.set("errorMessage","A valid zip code is required");
                            }
                        }
                        else{
                            _this.set("errorMessage","Target user is required");
                        }
                    }
                    else {
                        _this.set("errorMessage","http or https is required");
                    }
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
