import Ember from 'ember';

export function notEq(params/*, hash*/) {
    return (params[0] != params[1]); // not type
}

export default Ember.Helper.helper(notEq);
