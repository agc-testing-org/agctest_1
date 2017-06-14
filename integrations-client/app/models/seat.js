import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    name: attr('string'),
    created_at: attr('date')
});
