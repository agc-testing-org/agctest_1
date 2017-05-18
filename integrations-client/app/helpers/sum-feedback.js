import Ember from 'ember';

export function sumFeedback(params/*, hash*/) {
    var total = 0;
    if(params[0]){
        var contributions = params[0].toArray();
        for(var i = 0; i < contributions.length; i++){
            total = total + contributions[i].get(params[1]).toArray().length;
        }
    }

    return total; // not type
}

export default Ember.Helper.helper(sumFeedback);
