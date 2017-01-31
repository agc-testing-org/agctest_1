import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    after: attr('number'),
    user: DS.belongsTo('user'),
    sprint: DS.belongsTo('sprint'),
    state: DS.belongsTo('state'),
    label: DS.belongsTo('label'),
    project: DS.belongsTo('project'),
    created_at: attr('date')
});
