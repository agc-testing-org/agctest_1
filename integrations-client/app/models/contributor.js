import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    created_at: attr('date'),
    updated_at: attr('date'),
    repo: attr('string'),
    commit_remote: attr('string'),
    commit_success: attr('boolean'),
    sprint_state_id: attr('number')
});
