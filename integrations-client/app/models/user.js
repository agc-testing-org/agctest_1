import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    title: attr('string'),
    industry: attr('string'),
    size: attr('string'),
    location: attr('string'),
    created_at: attr('date')
});
