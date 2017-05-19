import Ember from 'ember';

export default Ember.Route.extend({
    store: Ember.inject.service(),

    model: function(params){

        return Ember.RSVP.hash({
            sprint: this.modelFor("develop.project.sprint").sprint,
        });
    },

    afterModel(model, transition){
        //#TODO - this model doesn't resolve properly before this is triggered
  //      var all = this.store.peekAll("sprint-states");
    //    console.log(all);
        //this.transitionTo('develop.project.sprint.state',all[all.length - 1].id);
    }
      
});
