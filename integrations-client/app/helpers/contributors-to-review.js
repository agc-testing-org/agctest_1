import Ember from 'ember';

export function contributorsToReview(params/*, hash*/) {
    var result = []
    if (params[0]) {
        var contributions = params[0].toArray();
        var index = params[1];
        for (var i = index; i < index + 3; i++) {
            result.push(contributions[i%contributions.length])
        }
    }
    return result;
}
export default Ember.Helper.helper(contributorsToReview);
