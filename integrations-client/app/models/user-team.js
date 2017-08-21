import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    accepted: attr('boolean'),
    team_id: attr('number'),
    seat_id: attr('number'),
    profile_id: attr('string'),
    sender_id: attr('string'),
    sender_first_name: attr('string'),
    sender_last_name: attr('string'),
    user_id: attr('string'),
    user_first_name: attr('string'),
    user_last_name: attr('string'),
    user_profile: DS.belongsTo('user-profile'), 
    user_email: attr('string'),
    share_profile: DS.belongsTo('user-profile'),
    share_first_name: attr('string'),
    share_last_name: attr('string'),
    registered: attr('boolean'),
    name: attr('string'),
    created_at: attr('date'),
    updated_at: attr('date'),
    team_comments: DS.belongsTo('team-comment'),
    team_votes: DS.belongsTo('team-vote'),
    team_contributors: DS.belongsTo('team-contributor'),
    team_comments_received: DS.belongsTo('team-comments-received'),
    team_votes_received: DS.belongsTo('team-votes-received'),
    team_contributors_received: DS.belongsTo('team-contributors-received'),
    job_id: attr('number'),
    job_company: attr('string'),
    job_title: attr('string'),
    job_team_name: attr('string')
});
