import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    id: attr('number'),
    email: DS.attr('string'),
	first_name: DS.attr('string'),
    seat_id: attr('number')
});