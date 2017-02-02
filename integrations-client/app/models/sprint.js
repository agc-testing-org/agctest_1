import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    title: attr('string'),
    description: attr('string'),
    user_id: attr('number'),
    state_id: attr('number'),
    project: DS.belongsTo('user'),
    deadline: attr('date'),
    sha: attr('string'),
    created_at: attr('date'),
    updated_at: attr('date')
});
