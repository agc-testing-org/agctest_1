import Ember from 'ember';

export function contributorsToReview(params/*, hash*/) {
    var result = []
    if (params[0] && params[1]) {
        var contributions = params[0].toArray();
        var index = params[1];
        var success_contributions = contributions.filterBy("commit_success",true);

        for (var i = index; i < index + 3; i++) {
            result.push(success_contributions[i%success_contributions.length])
        }
    }
    return result;
}
export default Ember.Helper.helper(contributorsToReview);
