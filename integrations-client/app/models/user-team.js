import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    accepted: attr('boolean'),
    team_id: attr('number'),
    seat_id: attr('number'),
    sender_id: attr('number'),
    sender_first_name: attr('string'),
    sender_last_name: attr('string'),
    user_id: attr('number'),
    user_first_name: attr('string'),
    user_last_name: attr('string'),
    user_email: attr('string'),
    registered: attr('boolean'),
    name: attr('string'),
    created_at: attr('date'),
    updated_at: attr('date')
});
