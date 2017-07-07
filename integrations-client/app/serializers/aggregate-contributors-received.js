import DS from 'ember-data';

export default DS.JSONSerializer.extend(DS.EmbeddedRecordsMixin, {
    attrs: {     
        sprint_state: { embedded: 'always' },
        next_sprint_state: { embedded: 'always' },
        user_profile: { embedded: 'always' },
        sprint: { embedded: 'always' },
        project: { embedded: 'always' }
    }
});
