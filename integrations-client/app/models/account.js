import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    name: attr('string'),
    admin: attr('boolean'),
    github: attr('boolean')
});
