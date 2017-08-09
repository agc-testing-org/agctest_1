import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    notification_id: attr('number'),
    notification: attr(),
    sprint: DS.belongsTo('sprint'),
    project: DS.belongsTo('project'),
    comment: DS.belongsTo('comment'),
    vote: DS.belongsTo('vote'),
    created_at: attr('date'),
    read: attr('boolean'),
    sprint_state: DS.belongsTo('sprint-state'),
    next_sprint_state: DS.belongsTo('sprint-state'),
    user_profile: DS.belongsTo('user-profile'),
    user_id: attr('string'),
    talent_profile: DS.belongsTo('user-profile'),
    talent_id: attr('string'),
    talent_first_name: attr('string'),
    sprint_state_id: attr('number'),
    state_id: DS.belongsTo('state'),
    job_id: attr('number'),
    job_title: attr('string'),
    job_team_name: attr('string')
});

