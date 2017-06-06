import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    body: attr('string'),
    sprint_id: attr('number'),
    sprint_name: attr('string'),
    project_org: attr('string'),
    project_name: attr('string'),
    project_id: attr('number'),
    created_at: attr('date'),
    read: attr('boolean'),
    sprint_state_id: attr('number'),
    subject: attr('string')
});

