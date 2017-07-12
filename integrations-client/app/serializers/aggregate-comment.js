import DS from 'ember-data';

export default DS.RESTSerializer.extend(DS.EmbeddedRecordsMixin, {

    normalizeResponse(store, primaryModelClass, payload, id, requestType) {
        payload = {
            aggregateComments: payload.data,
            meta: payload.meta
        };
        return this._super(store, primaryModelClass, payload, id, requestType);
    },

    attrs: {     
        sprint_state: { embedded: 'always' },
        next_sprint_state: { embedded: 'always' },
        user_profile: { embedded: 'always' },
        sprint: { embedded: 'always' },
        project: { embedded: 'always' },
        comment: { embedded: 'always' }
    }
});
