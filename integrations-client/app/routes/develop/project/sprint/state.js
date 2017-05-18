import Ember from 'ember';

export default Ember.Route.extend({
    store: Ember.inject.service(),
    actions: {

    },

    model: function(params){

        /*       
                 var allStatesPromise = this.store.findRecord('sprint', this.modelFor("develop.project.sprint").id);
                 return Ember.RSVP.hash({
                 review: allStatesPromise,
                 user: allStatesPromise.then(allStates => {
                 console.log(allStates.get("sprint_states"));
                 return allStates.get("sprint_states").toArray();
                 })
                 });
         */


        this.store.adapterFor('skillset').set('namespace', ''); // unset from sprint

        var valid_state = false;
        var last_contributor_state = {};
        var last_state = {};
        var ss = this.store.peekAll("sprint-state").toArray();

        if(ss.length > 0){
            last_state = ss[ss.length - 1];
        }

        for(var i = 0; i < ss.length; i++){
            console.log(ss.length+" "+ss[i].id+" "+params.state_id);
            if(ss[i].id === params.state_id){
                valid_state = true;
                if(i > 0){
                    last_contributor_state = ss[i - 1];
                }
            }
        }

        if(valid_state){

            return Ember.RSVP.hash({

                sprint: this.modelFor("develop.project.sprint").sprint,

                states: this.modelFor("develop.project").states,

                skillsets: this.modelFor("develop.project.sprint").skillsets,

                project: this.modelFor("develop.project").project,

                selected_state: this.store.peekRecord("sprint-state",params.state_id),

                last_state: last_state,

                last_contributor_state: last_contributor_state

            });


        }
        else {
//            this.transitionTo('develop.project.sprint.state',ss[ss.length - 1].id);
        }

    }
});
