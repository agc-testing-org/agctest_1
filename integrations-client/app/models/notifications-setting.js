import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    name: attr('string'),
    description: attr('string'),
    active: attr('boolean'),
    updated_at: attr('date')
});
