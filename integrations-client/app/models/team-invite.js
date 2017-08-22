import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    registered: attr('boolean'),
    expired: attr('boolean'),
    valid: attr('boolean'),
    name: attr('string'),
    company: attr('string'),
    created_at: attr('date'),
    updated_at: attr('date')
});
