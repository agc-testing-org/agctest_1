import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    sessionAccount: Ember.inject.service('session-account'),
    count: 2,
    showingAll: false,
    actions: {
        showAll(yesNo){
            var number = 2; 
            if(yesNo){
                number = this.get("sprints").toArray().length;
            }
            this.set("count",number);
            this.set("showingAll",yesNo);
        }
    }
});
