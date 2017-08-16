import Ember from 'ember';

export function sumFeedbackVote(params/*, hash*/) {
    var total = 0;
    if (params[0]) {
        var contributions = params[0].toArray();
        for (var i = 0; i < contributions.length; i++) {
            if(contributions[i].get(params[1])){
                var votes = contributions[i].get(params[1]).toArray();
                for (var j = 0; j < votes.length; j++) {
                    var data = votes[j].data;
                    if (data.comment_id == null) {
                        total = total + 1;
                    }
                }
            }
        }
    }

    return total;
}
export default Ember.Helper.helper(sumFeedbackVote);
