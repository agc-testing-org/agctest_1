import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    sender: attr('string'),
    email: attr('string'),
    registered: attr('boolean'),
    name: attr('string'),
    created_at: attr('date'),
    updated_at: attr('date')
});
