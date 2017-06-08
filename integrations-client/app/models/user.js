import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    created_at: attr('date')
});
