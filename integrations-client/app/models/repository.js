import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    name: attr('string'),
    owner: attr('string'),
    description: attr('string'),
    sprint_state_id: attr('number')
});
