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
	seat_id: DS.attr('number'),
	is_talent: DS.attr('boolean'),
    contact_first_name: DS.attr('string')
});
