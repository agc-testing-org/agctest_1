import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    name: attr('string'),
    seats: DS.hasMany('seat'),
    user: attr(),
    show: attr('boolean'),
    user_id: attr('string'),
    plan_id: attr('number'),
    plan: DS.belongsTo('plan'),
    default_seat_id: attr('number'), 
    created_at: attr('date'),
    updated_at: attr('date')
});
