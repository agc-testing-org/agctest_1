import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
	user_id: DS.attr('number'),
	first_name: DS.attr('string'),
	contact_id: DS.attr('number'),
	read: DS.attr('boolean'),
	confirmed: DS.attr('number')
});
