import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    user_id: attr('number'),
    state: DS.belongsTo('state'),
    deadline: attr('date'),
    sha: attr('string'),
    contributors: DS.hasMany('contributor'),
    created_at: attr('date'),
    updated_at: attr('date')
});
