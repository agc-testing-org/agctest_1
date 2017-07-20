import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    first_name: attr('string'),
    last_name: attr('string'),
    admin: attr('boolean'),
    seat_id: DS.belongsTo("seat"),
    github: attr('boolean'),
    github_username: attr('string')
});
