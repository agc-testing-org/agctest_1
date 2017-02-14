import Ember from 'ember';

export function limited(params/*, hash*/) {
    if(params[0]){
        return params[0].slice(0,params[1]);
    }
    else {
        return null;
    }
}

export default Ember.Helper.helper(limited);

