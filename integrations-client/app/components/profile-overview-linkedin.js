import Ember from 'ember';

export default Ember.Component.extend({
    actions: {
        refresh(){
            this.sendAction("refresh");
        }
    }
});
