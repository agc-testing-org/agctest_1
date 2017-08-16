import Ember from 'ember';

export function sumFeedback(params/*, hash*/) {
    var total = 0;
    if(params[0]){
        var contributions = params[0].toArray();
        for(var i = 0; i < contributions.length; i++){
            var comments = contributions[i].get(params[1]).toArray();
            if(comments){
                var not_explain = comments.filterBy("explain",false);
                if(not_explain){
                    total = total + not_explain.length;
                }
            }
        }
    }

    return total; // not type
}

export default Ember.Helper.helper(sumFeedback);
