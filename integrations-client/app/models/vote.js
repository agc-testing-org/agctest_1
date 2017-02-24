import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    created: attr('boolean'),
    created_at: attr('date'),
    updated_at: attr('date'),
    contributor_id: attr('number'),
    sprint_state_id: attr('number'),
    sprint_state: DS.belongsTo('sprint-state'),
    user_id: attr('number')
});
