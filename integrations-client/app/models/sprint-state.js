import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    active_contribution_id: attr('number'),
    contributor_id: attr('number'),
    arbiter_id: attr('number'),
    sprint_id: DS.belongsTo('sprint'),
    state_id: DS.belongsTo('state'),
    sprint: attr('number'),
    state: attr('number'),
    deadline: attr('date'),
    sha: attr('string'),
    contributors: DS.hasMany('contributor'),
    created_at: attr('date'),
    updated_at: attr('date'),
    pull_request: attr('number'),
    merged: attr('boolean')
});
