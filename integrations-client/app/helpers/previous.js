import Ember from 'ember';

export default Ember.Helper.extend({
    store: Ember.inject.service(),
    compute(params) {
        var record = this.get('store').peekRecord(params[0],params[1]);
        if(record){ 
            return record;
        }
        else {
            console.log("NOPE");
            return null;
        }
    }
});
