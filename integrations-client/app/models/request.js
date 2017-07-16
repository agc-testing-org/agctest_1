import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    user_id: attr('string'),	
	first_name: DS.attr('string'),
    contact_id: attr('string'),
	read: DS.attr('boolean'),
	confirmed: DS.attr('number')
});
