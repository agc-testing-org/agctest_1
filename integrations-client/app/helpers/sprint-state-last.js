import Ember from 'ember';

export default Ember.Helper.extend({
    store: Ember.inject.service(),
    compute(params) {
        var ss = params[0].toArray();
        return ss[ss.length - 1];
    }
});
