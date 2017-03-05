import Ember from 'ember';

export function includes(params/*, hash*/) {
    var included = false;
    if(params[0]){
        for(var i = 0; i < Object.keys(params[0]).length; i++){
            if(params[0][params[1]]){
                included = true;
            }
        }
    }    
    return included;
}

export default Ember.Helper.helper(includes);

