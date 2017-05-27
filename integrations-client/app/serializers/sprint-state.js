import DS from 'ember-data';

export default DS.JSONSerializer.extend(DS.EmbeddedRecordsMixin, {
    attrs: {
      //  state: { embedded: 'always' },
        contributors: { embedded: 'always' }
    }
});
