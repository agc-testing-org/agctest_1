import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    count: 1,
    showingAll: false,
    actions: {
        showAll(yesNo){
            var number = 1;
            if(yesNo){
                number = this.get("values").toArray().length;
            }
            this.set("count",number);
            this.set("showingAll",yesNo);
        }
    }
});
