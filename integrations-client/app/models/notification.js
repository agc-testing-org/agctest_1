import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
	subject: attr('string'),
    body: attr('string'),
    sprint_id: attr('number')
});
