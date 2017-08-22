import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    name: attr('string'),
    company: attr('string'),
    seats: DS.hasMany('seat'),
    user: attr(),
    show: attr('boolean'),
    shares: attr('boolean'),
    user_id: attr('string'),
    plan_id: attr('number'),
    plan: DS.belongsTo('plan'),
    default_seat_id: DS.belongsTo('seat'), 
    created_at: attr('date'),
    updated_at: attr('date')
});
