import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    count: 2,
    showingAll: false,
    init() {
        this._super(...arguments);
        if(!this.get("limit_results")){
            this.set("count",this.get("items.meta.count"));
        }
    },
    actions: {
        showAll(yesNo){
            var number = 2;
            if(yesNo){
                number = this.get("items").toArray().length;
            }
            this.set("count",number);
            this.set("showingAll",yesNo);
        },
    }
});
