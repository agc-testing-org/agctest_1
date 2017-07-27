import DS from 'ember-data';

export default DS.JSONSerializer.extend(DS.EmbeddedRecordsMixin, {
    attrs: {
        team: { embedded: 'always' },
        share_profile: { embedded: 'always' }
    }
});
