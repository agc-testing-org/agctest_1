import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    sessionAccount: Ember.inject.service('session-account'),
    errorMessage: null, 
    showInvite: null,
    init() { 
        this._super(...arguments);   
    },
    actions: {
        displayInvite(){
            if(this.get("showInvite")){
                this.set("showInvite",false);
            }   
            else{
                this.set("showInvite",true);
            }   
        }, 
        refresh(){
            this.sendAction("refresh");
        }
    }

});
