import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    sprint: DS.belongsTo('sprint'),
    project: DS.belongsTo('project'),
    comment: DS.belongsTo('comment'),
    vote: DS.belongsTo('vote'),
    created_at: attr('date'),
    sprint_state: DS.belongsTo('sprint-state'),
    next_sprint_state: DS.belongsTo('sprint-state'),
    user_profile: DS.belongsTo('user-profile'),
});

