import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    name: attr('string'),
    description: attr('string'),
    fa_icon: attr('string'),
    instruction: attr('string'),
    contributors: attr('boolean')
});
