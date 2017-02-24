import DS from 'ember-data';

export default DS.JSONSerializer.extend(DS.EmbeddedRecordsMixin, {
    attrs: {     
        sprint_state: { embedded: 'always' }
    }
});
