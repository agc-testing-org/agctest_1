import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    notification_id: attr('number'),
    notification: attr(),
    sprint: DS.belongsTo('sprint'),
    project: DS.belongsTo('project'),
    comment: DS.belongsTo('comment'),
    contributor_id: attr('number'),
    contributor_profile: attr(),
    contributor_first_name: attr('string'),
    vote: DS.belongsTo('vote'),
    created_at: attr('date'),
    read: attr('boolean'),
    sprint_state: DS.belongsTo('sprint-state'),
    next_sprint_state: DS.belongsTo('sprint-state'),
    user_profile: DS.belongsTo('user-profile'),
    user_first_name: attr('string'),
    user_id: attr('string'),
    sprint_state_id: attr('number'),
    state_id: DS.belongsTo('state'),
    comment_vote: attr(),
    comment_vote_user_profile: attr(),
    comment_vote_first_name: attr('string'),
    job_id: attr('number'),
    job_title: attr('string'),
    job_team_name: attr('string'),
    job_company: attr('string')
});

