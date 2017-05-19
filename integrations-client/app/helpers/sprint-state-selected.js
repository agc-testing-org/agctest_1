import Ember from 'ember';

export default Ember.Helper.extend({
    store: Ember.inject.service(),
    compute(params) {
        if(params[0]){
            return this.get('store').peekRecord("sprint-state",params[1]);
        }
    }
});
