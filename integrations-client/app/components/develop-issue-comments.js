import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    count: 3,
    showingAll: false,
    sortedComments: Ember.computed.sort('comments', 'sortDefinition'),
    sortDefinition: ['created_at:desc'],
    actions: {
        showAll(yesNo){
            var number = 3;
            if(yesNo){
                number = this.get("comments").toArray().length;
            }
            this.set("count",number);
            this.set("showingAll",yesNo);
        }
    }
});
