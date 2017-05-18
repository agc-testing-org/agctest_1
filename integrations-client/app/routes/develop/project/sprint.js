import Ember from 'ember';

export default Ember.Route.extend({
    store: Ember.inject.service(),
    actions: {
        refresh(){
            console.log("refreshing router");
            this.refresh();
        }
    },
    model: function(params){
        this.store.adapterFor('skillset').set('namespace', 'sprints/' + params.id );

 //       var sprintPromise = this.store.findRecord('sprint', params.id);

//        var all_states = new Array();

//        var last_state = {}; 

        /*
        sprintPromise.then(function(sprint){
            all_states = sprint.get("sprint_states").then(function(ss){
                return ss;
            }).then(function(ss){
                if(ss.length > 0){        
                    return ss[ss.length - 1]; 
                } 
            });
        });

        */

        return Ember.RSVP.hash({
            id: params.id,
            states: this.modelFor("develop.project").states,
            sprint: this.store.findRecord('sprint', params.id),
         //   sprint_states:all_states,
         //   last_state: last_state,
            skillsets: this.store.query('skillset', {

            }),
        });
    }

});
