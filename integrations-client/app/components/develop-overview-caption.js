import Ember from 'ember';

const { inject: { service }, Component } = Ember;

export default Component.extend({
    session: service('session'),
    sessionAccount: Ember.inject.service('session-account'),
    store: Ember.inject.service(),
    showUpdate: null,
    errorMesssage: null,
    didRender() {
        this._super(...arguments);
    },
    actions: {
        show(){
            if(this.get("showUpdate")){
                this.set("showUpdate",false);
            }
            else {
                this.set("showUpdate",true);
            }
        },
        update(project_id, caption){
            var _this = this;
            var store = this.get('store');
            _this.set("errorMessage",null);

            if(caption && caption.length > 4 && caption.length < 501){

                var projectUpdate = store.findRecord('project',project_id).then(function(project) {
                    project.set('caption', caption);
                    project.save().then(function() {
                        _this.set("showUpdate",false);
                    }, function(xhr, status, error) {
                        var response = xhr.errors[0].detail;
                        _this.set("errorMessage",response);
                    });
                });
            } else {
                _this.set('errorMessage', "caption must be 5-500 characters");
            }
        }
    }

});
