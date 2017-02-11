import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    created_at: attr('date'),
    updated_at: attr('date'),
    commit_remote: attr('string'),
    commit_success: attr('boolean')
});
