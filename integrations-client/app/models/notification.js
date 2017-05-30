import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    body: attr('string'),
    sprint_id: attr('number'),
    sprint_name: attr('string'),
    project: attr('string'),
    created_at: attr('date'),
    read: attr('boolean')
});

