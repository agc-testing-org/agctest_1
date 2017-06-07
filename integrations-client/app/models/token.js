import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    token: attr('string'),
    created_at: attr('date'),
    updated_at: attr('date'),
    team_id: attr('number')
});
