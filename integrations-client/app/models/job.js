import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    title: attr('string'),
    link: attr('string'),
    team_id: attr('number'),
    role_id: attr('number'),
    role: DS.belongsTo('role'),
    sprint_id: attr('number'),
    team_name: attr('string'),
    user_first_name: attr('string'),
    created_at: attr('date'),
    updated_at: attr('date'),
    sprints: DS.hasMany('sprints')
});
