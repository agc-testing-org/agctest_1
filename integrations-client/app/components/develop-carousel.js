import Ember from 'ember';

export default Ember.Component.extend({
    visibleProjects: Ember.computed.filterBy('projects','hidden', false),
    init() {
        this._super(...arguments);   
    },
    actions: {
    }

});
