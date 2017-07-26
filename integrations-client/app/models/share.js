import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    accepted: attr('boolean'),
    team_id: attr('number'),
    team: DS.belongsTo('team'),
    profile_id: attr('string'),
    sender_id: attr('string'),
    sender_first_name: attr('string'),
    sender_last_name: attr('string'),
    share_profile: DS.belongsTo('user-profile'),
    share_first_name: attr('string'),
    share_last_name: attr('string'),
    created_at: attr('date'),
    updated_at: attr('date'),
    token: attr('string')
});
