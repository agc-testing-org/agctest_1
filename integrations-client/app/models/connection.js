import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
	first_name: DS.attr('string'),
    email: DS.attr('string'),
    created_at: attr('date'),
    updated_at: attr('date'),
    contact_id: attr('number'),
    user_id: attr('number')
});
