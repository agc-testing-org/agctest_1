import Ember from 'ember';

export function and(params/*, hash*/) {
    return (params[0] && params[1]); // not type
}

export default Ember.Helper.helper(and);
