import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    name: attr('string'),
    seats: DS.hasMany('seat'),
    default_seat_id: attr('number'), 
    created_at: attr('date'),
    updated_at: attr('date')
});
