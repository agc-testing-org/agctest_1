import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    displayCreate: null,
    errorMessage: null,
    init() {
        this._super(...arguments);
    },
    actions: {
        showCreate(){
            if(this.get("displayCreate")){
                this.set("displayCreate",false);
            }
            else{
                this.set("displayCreate",true);
            }
        },
        createSprint(){
            var _this = this;
            var title = this.get("title");
            var description = this.get("description");
            if(title && title.length > 5){
                if(description && description.length > 5){
                    var store = this.get('store');
                    var sprint = store.createRecord('sprint', {
                        title: title,
                        description: description
                    }).save().then(function(payload) {
                        store.peekAll('sprint').addObject(payload);
                        _this.set("title","");
                        _this.set("description","");
                        _this.send("showCreate");
                    }, function(xhr, status, error) {

                    });
                }
                else {
                    this.set('errorMessage', "Please enter a more detailed description");
                }
            }
            else {
                this.set('errorMessage', "Please enter a longer title");
            }
        }
    }

});
