import Ember from 'ember';

export function sumFeedbackVote(params/*, hash*/) {
    var total = 0;
    if (params[0]) {
        var contributions = params[0].toArray();
        for (var i = 0; i < contributions.length; i++) {
            if(contributions[i].get(params[1])){
                console.log(contributions[i]); 
                var votes = contributions[i].get(params[1]).toArray();
                var votes_count = [];
                for (var j = 0; j < votes.length; j++) {
                    var data = votes[j].data;
                    if (data.comment_id == null) {
                        votes_count.push(votes[j]);
                    }
                    total = total + votes_count.length;
                }
            }
        }
    }

    return total;
}
export default Ember.Helper.helper(sumFeedbackVote);
