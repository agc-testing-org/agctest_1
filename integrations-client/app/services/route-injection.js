import Ember from 'ember';

export default Ember.Service.extend({
    routing: Ember.inject.service('-routing'),
    init() {
        this._super(...arguments);
    },
    redirect(to){
        this.get("routing").transitionTo(to);
    },
    redirectWithId(to,id){
        this.get("routing").transitionTo(to,[id]);
    }
});
