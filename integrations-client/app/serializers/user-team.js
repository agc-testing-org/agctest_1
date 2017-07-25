import DS from 'ember-data';

export default DS.JSONSerializer.extend(DS.EmbeddedRecordsMixin, {
    attrs: {     
        user_profile: { embedded: 'always' },
        share_profile: { embedded: 'always' }
    }
});
