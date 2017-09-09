import Ember from 'ember';

export default Ember.Component.extend({
    activeRoles: Ember.computed.filterBy("roles","active",true),
    recruiter: Ember.computed.filterBy("activeRoles","name","recruiting"),
    manager: Ember.computed.filterBy("activeRoles","name","management"),
    didRender() {
        this._super(...arguments);
        this.$('#masonry').masonry({});
    },
    actions: {
        refresh(){
            this.sendAction("refresh");
        }
    }
});
