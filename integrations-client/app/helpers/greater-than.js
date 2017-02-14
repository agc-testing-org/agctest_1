import Ember from 'ember';

export function greaterThan(params/*, hash*/) {
    return (parseInt(params[0]) > parseInt(params[1])); // not type
}

export default Ember.Helper.helper(greaterThan);
