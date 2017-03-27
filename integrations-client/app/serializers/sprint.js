import DS from 'ember-data';

export default DS.JSONSerializer.extend(DS.EmbeddedRecordsMixin, {
    attrs: {
        project: { 
//            serialize: 'records',
            deserialize: 'records'
        },//{ embedded: 'always' },
        sprint_states: {
  //          serialize: 'records',
            deserialize: 'records'
        }//{ embedded: 'always' }
    }
});
