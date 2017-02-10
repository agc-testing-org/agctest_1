import Ember from 'ember';

export function match(params/*, hash*/) {
    if((params[1][params[0]]) === (params[2][params[0]])){
        return true;
    }
    else {
        return false;
    }
}

export default Ember.Helper.helper(match);
