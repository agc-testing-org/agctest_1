import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    name: attr('string'),
    fa_icon: attr('string'),
    active: attr('boolean')
});
