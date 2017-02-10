import Ember from 'ember';

export function plus(params/*, hash*/) {
    return (params[0] + params[1]); // not type
}

export default Ember.Helper.helper(plus);
