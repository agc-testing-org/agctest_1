import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    errorMessage: null,
    showShare: false,
    actions: {
        refresh(){
            this.sendAction("refresh");
        },
        show(){
            if(this.get("showShare")){
                this.set("showShare",false);
            }
            else{
                this.set("showShare",true);
            }
        }
    }

});
