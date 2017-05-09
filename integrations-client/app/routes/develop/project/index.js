import Ember from 'ember';

export default Ember.Route.extend({

    beforeModel(){
        this.transitionTo('develop.project.state',"all");
    }
});
