import Ember from 'ember';

export default Ember.Helper.extend({
    store: Ember.inject.service(),
    compute(params) {
        var ss = params[0].toArray();
        var last_contributor_state = {};
        for(var i = 0; i < ss.length; i++){
            if(ss[i].id === params[1]){
                if(i > 0){                                  
                    last_contributor_state = ss[i - 1];                                                                
                }                                                                                   
            }                                                           
        }
        return last_contributor_state;
    }
});
