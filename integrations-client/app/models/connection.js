import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
	first_name: DS.attr('string'),
	email: DS.attr('string')
});