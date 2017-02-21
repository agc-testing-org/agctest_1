import DS from 'ember-data';

export default DS.JSONSerializer.extend(DS.EmbeddedRecordsMixin, {
    attrs: {
        sprint: { embedded: 'always' },
        state: { embedded: 'always' },
        label: { embedded: 'always' },
        user: { embedded: 'always' },
        sprint_state: { embedded: 'always' }
    }
});
