import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
	first_name: DS.attr('string'),
    email: DS.attr('string'),
    created_at: attr('date'),
    updated_at: attr('date'),
    contact_id: attr('string'),
    user_id: attr('string'),
    user_profile: DS.belongsTo('user-profile'),
    read: DS.attr('boolean'),
	confirmed: DS.attr('number'),
	team_id: DS.attr('number'),
    team_name: DS.attr('string'),
    team_company: DS.attr('string'),
	seat_id: DS.attr('number'),
    contact_first_name: DS.attr('string'),
    expires: attr('date'),
});
