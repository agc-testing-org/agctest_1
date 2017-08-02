import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    name: attr('string'),
    org: attr('string'),
    description: attr('string'),
    caption: attr('string'),
    created_at: attr('date'),
    updated_at: attr('date')
});
