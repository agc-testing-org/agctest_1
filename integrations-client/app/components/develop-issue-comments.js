import Ember from 'ember';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    store: Ember.inject.service(),
    sessionAccount: Ember.inject.service('session-account'),
    count: 2,
    showingAll: false,
    orderedComments: Ember.computed.sort('comments', 'sortDefinition'),
    sortedComments: function() {
        if(this.get('orderedComments')){
            return this.get('orderedComments').filterBy('explain',false);
        }
        else{
            return [];
        }
    }.property('orderedComments.@each'),
    explainComments: Ember.computed.filterBy('comments', 'explain', true),
    sortDefinition: ['created_at:desc'],
    actions: {
        showAll(yesNo){
            var number = 2;
            if(yesNo){
                number = this.get("comments").toArray().length;
            }
            this.set("count",number);
            this.set("showingAll",yesNo);
        },
    }
});
