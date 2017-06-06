import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    sender_email: attr('string'),
    sender_first_name: attr('string'),
    registered: attr('boolean'),
    name: attr('string'),
    created_at: attr('date'),
    updated_at: attr('date')
});
